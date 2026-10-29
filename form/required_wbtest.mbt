///|
fn required_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  for id in [5, 8] {
    d.add_object_given_number(
      id,
      d.direct(PdfIndirect(id)).add_dict_entry(name("Ff"), PdfInteger(2)),
    )
  }
  @pdf.pdf_write_document(d)
}

///|
test "completion distinguishes draft and missing required values and recovers" {
  let f = Form::open(required_fixture())
  assert_eq(f.missing_required(), ["approved", "customer"])
  ignore(f.fill({ "customer": Text(" ") }))
  for
    row in [
      { "approved": Checked(true) },
      { "approved": Checked(true), "customer": Text(" ") },
      { "approved": Checked(false), "customer": Text("Ada") },
    ] {
    assert_true(
      try {
        ignore(f.fill(row, complete=true))
        false
      } catch {
        _ => true
      },
    )
  }
  let values : Map[String, Value] = {
    "approved": Checked(true),
    "customer": Text("Ada"),
  }
  let done = f.fill(values, complete=true)
  assert_eq(done, f.fill(values))
  assert_eq(Form::open(done).missing_required(), [])
  assert_eq(f.missing_required(), ["approved", "customer"])
  assert_eq(
    Form::open(Form::open(done).fill({}, complete=true)).missing_required(),
    [],
  )
  assert_true(
    try {
      ignore(
        f.fill_batch([values, { "customer": Text("Grace") }], complete=true),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_eq(f.fill_batch([values], complete=true)[0], done)
}

///|
test "required flags and values inherit and unsupported required fields fail" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let child = d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("Parent"), PdfIndirect(9))
  d.add_object_given_number(8, child)
  d.add_object_given_number(
    9,
    PdfDictionary([
      (name("T"), PdfString(b"group")),
      (name("Ff"), PdfInteger(3)),
      (name("V"), PdfString(b"Inherited")),
      (name("Kids"), PdfArray([PdfIndirect(8)])),
    ]),
  )
  d.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(9)]))]),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_eq(f.value("group.customer"), Some(Text("Inherited")))
  assert_eq(f.missing_required(), [])
  d.add_object_given_number(
    8,
    child.add_dict_entry(name("FT"), PdfNameObject(name("Custom"))),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_true(
    try {
      ignore(f.missing_required())
      false
    } catch {
      _ => true
    },
  )
}
