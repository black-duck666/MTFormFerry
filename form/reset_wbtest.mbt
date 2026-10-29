///|
test "reset restores defaults in source order and leaves other values intact" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    5,
    d
    .direct(PdfIndirect(5))
    .add_dict_entry(name("DV"), PdfNameObject(name("Yes"))),
  )
  d.add_object_given_number(
    8,
    d.direct(PdfIndirect(8)).add_dict_entry(name("DV"), PdfString(b"Guest")),
  )
  let f = Form::open(
    Form::open(@pdf.pdf_write_document(d)).fill({
      "customer": Text("Ada"),
      "approved": Checked(false),
    }),
  )
  let bytes = f.reset(["customer", "approved"])
  let reset = Form::open(bytes)
  assert_eq(reset.value("customer"), Some(Text("Guest")))
  assert_eq(reset.value("approved"), Some(Checked(true)))
  assert_eq(bytes, f.reset(["approved", "customer"]))
  assert_eq(bytes[:f.original.length()].to_owned(), f.original)
  let one = Form::open(f.reset(["customer"]))
  assert_eq(one.value("approved"), f.value("approved"))
  assert_eq(f.value("customer"), Some(Text("Ada")))
  let draft = Form::open(
    Form::open(required_fixture()).fill({
      "customer": Text("Ada"),
      "approved": Checked(true),
    }),
  )
  assert_true(
    try {
      ignore(draft.reset(["customer"], complete=true))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(
    Form::open(draft.reset(["customer"])).value("customer"),
    Some(Text("")),
  )
}

///|
test "reset handles radio dropdown and multi defaults and clears missing defaults" {
  let d = @pdf.pdf_read_document_from_bytes(radio_fixture())
  let original = d.direct(PdfIndirect(5))
  d.add_object_given_number(
    5,
    original.add_dict_entry(name("DV"), PdfNameObject(name("Yes"))),
  )
  let f = Form::open(
    Form::open(@pdf.pdf_write_document(d)).fill({ "answer": Selected("No") }),
  )
  assert_eq(
    Form::open(f.reset(["answer"])).value("answer"),
    Some(Selected("Yes")),
  )
  let f = Form::open(
    Form::open(radio_fixture()).fill({ "answer": Selected("Yes") }),
  )
  let cleared = Form::open(f.reset(["answer"]))
  assert_eq(cleared.value("answer"), None)
  ignore(cleared.values_json())
  let f = Form::open(
    Form::open(dropdown_fixture()).fill({ "customer": Selected("exp") }),
  )
  assert_eq(Form::open(f.reset(["customer"])).value("customer"), None)
  let d = @pdf.pdf_read_document_from_bytes(multi_fixture())
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("DV"), PdfArray([PdfString(b"Standard")])),
  )
  let f = Form::open(
    Form::open(@pdf.pdf_write_document(d)).fill({
      "customer": Selections(["exp"]),
    }),
  )
  assert_eq(
    Form::open(f.reset(["customer"], complete=true)).value("customer"),
    Some(Selections(["Standard"])),
  )
  let f = Form::open(
    Form::open(multi_fixture()).fill({ "customer": Selections(["exp"]) }),
  )
  assert_eq(Form::open(f.reset(["customer"])).value("customer"), None)
}

///|
test "reset refuses malformed defaults unknown duplicate and read-only fields and recovers" {
  let f = Form::open(text_fixture())
  for
    fields in [
      [],
      ["missing"],
      ["customer", "customer"],
      ["customer", "missing"],
    ] {
    assert_true(
      try {
        ignore(f.reset(fields))
        false
      } catch {
        _ => true
      },
    )
  }
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let original = d.direct(PdfIndirect(8))
  for
    field in [
      original.add_dict_entry(name("Ff"), PdfInteger(1)),
      original.add_dict_entry(name("DV"), PdfInteger(1)),
      original.add_dict_entry(name("DV"), PdfString(b"x".repeat(31))),
    ] {
    d.add_object_given_number(8, field)
    assert_true(
      try {
        ignore(Form::open(@pdf.pdf_write_document(d)).reset(["customer"]))
        false
      } catch {
        _ => true
      },
    )
  }
  let original = d.direct(PdfIndirect(5))
  d.add_object_given_number(
    5,
    original.add_dict_entry(name("DV"), PdfNameObject(name("Unknown"))),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(d)).reset(["approved"]))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(Form::open(f.reset(["customer"])).value("customer"), Some(Text("")))
}

///|
test "reset inherits defaults but refuses exposing an inherited current choice" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    8,
    d.direct(PdfIndirect(8)).add_dict_entry(name("Parent"), PdfIndirect(9)),
  )
  d.add_object_given_number(
    9,
    PdfDictionary([
      (name("T"), PdfString(b"group")),
      (name("DV"), PdfString(b"Inherited")),
      (name("Kids"), PdfArray([PdfIndirect(8)])),
    ]),
  )
  d.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(9)]))]),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_eq(
    Form::open(f.reset(["group.customer"])).value("group.customer"),
    Some(Text("Inherited")),
  )
  let d = @pdf.pdf_read_document_from_bytes(dropdown_fixture())
  d.add_object_given_number(
    8,
    d.direct(PdfIndirect(8)).add_dict_entry(name("Parent"), PdfIndirect(9)),
  )
  d.add_object_given_number(
    9,
    PdfDictionary([
      (name("T"), PdfString(b"group")),
      (name("V"), PdfString(b"Standard")),
      (name("Kids"), PdfArray([PdfIndirect(8)])),
    ]),
  )
  d.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(9)]))]),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(d)).reset(["group.customer"]))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "reset text defaults supports bounded fitting and radio reset permits Off" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("DV"), PdfString(b"1234567890"))
    .add_dict_entry(
      name("Rect"),
      PdfArray([PdfInteger(0), PdfInteger(0), PdfInteger(40), PdfInteger(20)]),
    ),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_true(
    try {
      ignore(f.reset(["customer"]))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(
    Form::open(f.reset(["customer"], fit_text=true)).value("customer"),
    Some(Text("1234567890")),
  )
  let d = @pdf.pdf_read_document_from_bytes(radio_fixture())
  d.add_object_given_number(
    5,
    d.direct(PdfIndirect(5)).add_dict_entry(name("Ff"), PdfInteger(49152)),
  )
  let f = Form::open(
    Form::open(@pdf.pdf_write_document(d)).fill({ "answer": Selected("Yes") }),
  )
  let reset = Form::open(f.reset(["answer"]))
  assert_eq(reset.value("answer"), None)
  ignore(reset.values_json())
}
