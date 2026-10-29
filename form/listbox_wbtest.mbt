///|
fn list_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(dropdown_fixture())
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("Ff"), PdfInteger(2))
    .add_dict_entry(name("TI"), PdfInteger(1))
    .add_dict_entry(
      name("Rect"),
      PdfArray([
        PdfInteger(20),
        PdfInteger(60),
        PdfInteger(250),
        PdfInteger(120),
      ]),
    ),
  )
  @pdf.pdf_write_document(d)
}

///|
test "listbox highlights the display label and synchronizes V I TI" {
  let source = list_fixture()
  let f = Form::open(source)
  assert_eq(f.fields()[1].kind, Listbox)
  assert_eq(f.choices("customer"), ["Standard", "exp"])
  assert_eq(f.missing_required(), ["customer"])
  let bytes = f.fill({ "customer": Selected("exp") }, complete=true)
  let result = Form::open(bytes)
  assert_eq(result.value("customer"), Some(Selected("exp")))
  assert_eq(
    values_from_json(result.values_json()).get("customer"),
    Some(Selected("exp")),
  )
  assert_eq(result.value("approved"), f.value("approved"))
  let c = result.controls[1]
  assert_eq(
    get(result.document, c.object, "I"),
    Some(PdfArray([PdfInteger(1)])),
  )
  assert_eq(get(result.document, c.object, "TI"), Some(PdfInteger(0)))
  let ap = get(result.document, c.widgets[0].1, "AP").unwrap()
  let operators = @utf8.decode(
    get(result.document, ap, "N").unwrap().stream_bytes(),
  )
  assert_true(operators.contains("(Standard) Tj"))
  assert_true(operators.contains("(Express) Tj"))
  assert_true(operators.contains("0.85 g"))
  assert_eq(bytes[:source.length()].to_owned(), source)
  assert_eq(bytes, f.fill({ "customer": Selected("exp") }))
  let from_csv = f.fill_batch(
    f.records_from_csv("customer\nexp"),
    complete=true,
  )
  assert_eq(from_csv[0], bytes)
  assert_eq(
    Form::open(result.fill({ "customer": Selected("Standard") })).value(
      "customer",
    ),
    Some(Selected("Standard")),
  )
}

///|
test "listbox refuses scrolling clipping unsupported flags and choices and recovers" {
  let source = list_fixture()
  let d = @pdf.pdf_read_document_from_bytes(source)
  let original = d.direct(PdfIndirect(8))
  for
    field in [
      original.add_dict_entry(name("Ff"), PdfInteger(2097152)),
      original.add_dict_entry(name("Ff"), PdfInteger(524288)),
      original.add_dict_entry(
        name("Rect"),
        PdfArray([PdfInteger(0), PdfInteger(0), PdfInteger(230), PdfInteger(20)]),
      ),
      original.add_dict_entry(
        name("Rect"),
        PdfArray([PdfInteger(0), PdfInteger(0), PdfInteger(20), PdfInteger(60)]),
      ),
      original.add_dict_entry(
        name("Opt"),
        PdfArray([PdfString(b"same"), PdfString(b"same")]),
      ),
    ] {
    d.add_object_given_number(8, field)
    let f = Form::open(@pdf.pdf_write_document(d))
    assert_true(
      try {
        ignore(f.fill({ "customer": Selected("exp") }))
        false
      } catch {
        _ => true
      },
    )
  }
  let f = Form::open(source)
  assert_true(
    try {
      ignore(f.fill({ "customer": Selected("Express") }))
      false
    } catch {
      _ => true
    },
  )
  ignore(f.fill({ "customer": Selected("Standard") }))
}

///|
test "listbox updates every widget and rejects contradictory snapshot indices" {
  let d = @pdf.pdf_read_document_from_bytes(list_fixture())
  let original = d.direct(PdfIndirect(8))
  let widget = original
    .remove_dict_entry(name("T"))
    .remove_dict_entry(name("FT"))
    .add_dict_entry(name("Parent"), PdfIndirect(8))
  d.add_object_given_number(9, widget)
  d.add_object_given_number(10, widget.deep_copy())
  d.add_object_given_number(
    8,
    original
    .remove_dict_entry(name("Subtype"))
    .remove_dict_entry(name("Rect"))
    .add_dict_entry(name("Kids"), PdfArray([PdfIndirect(9), PdfIndirect(10)])),
  )
  d.add_object_given_number(
    3,
    d
    .direct(PdfIndirect(3))
    .add_dict_entry(
      name("Annots"),
      PdfArray([PdfIndirect(5), PdfIndirect(9), PdfIndirect(10)]),
    ),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  let bytes = f.fill({ "customer": Selected("exp") })
  let result = Form::open(bytes)
  for (_, w) in result.controls[1].widgets {
    let ap = get(result.document, w, "AP").unwrap()
    let drawing = @utf8.decode(
      get(result.document, ap, "N").unwrap().stream_bytes(),
    )
    assert_true(drawing.contains("(Express) Tj"))
    assert_true(drawing.contains("0.85 g"))
  }
  let d = @pdf.pdf_read_document_from_bytes(bytes)
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("I"), PdfArray([PdfInteger(0)])),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(d)).values_json())
      false
    } catch {
      _ => true
    },
  )
}
