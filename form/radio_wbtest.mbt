///|
fn radio_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(fixture())
  let original = d.direct(PdfIndirect(5))
  let ap = get(d, original, "AP").unwrap()
  let widget = original
    .remove_dict_entry(name("FT"))
    .remove_dict_entry(name("T"))
    .add_dict_entry(name("Parent"), PdfIndirect(5))
  d.add_object_given_number(8, widget)
  let other = ap.add_dict_entry(
    name("N"),
    PdfDictionary([(name("Off"), PdfIndirect(6)), (name("No"), PdfIndirect(7))]),
  )
  d.add_object_given_number(9, widget.add_dict_entry(name("AP"), other))
  d.add_object_given_number(
    5,
    PdfDictionary([
      (name("T"), PdfString(b"answer")),
      (name("FT"), PdfNameObject(name("Btn"))),
      (name("Ff"), PdfInteger(32768)),
      (name("Kids"), PdfArray([PdfIndirect(8), PdfIndirect(9)])),
    ]),
  )
  let page = d.direct(PdfIndirect(3))
  d.add_object_given_number(
    3,
    page.add_dict_entry(
      name("Annots"),
      PdfArray([PdfIndirect(8), PdfIndirect(9)]),
    ),
  )
  @pdf.pdf_write_document(d)
}

///|
test "radio choices select one widget and switch without losing original" {
  let source = radio_fixture()
  let f = Form::open(source)
  assert_eq(f.choices("answer"), ["Yes", "No"])
  let bytes = f.fill(values_from_text("{\"answer\":{\"select\":\"No\"}}"))
  let result = Form::open(bytes)
  assert_eq(result.value("answer"), Some(Selected("No")))
  assert_eq(
    get(result.document, result.controls[0].widgets[0].1, "AS"),
    Some(PdfNameObject(name("Off"))),
  )
  assert_eq(
    get(result.document, result.controls[0].widgets[1].1, "AS"),
    Some(PdfNameObject(name("No"))),
  )
  assert_eq(
    Form::open(result.fill({ "answer": Selected("Yes") })).value("answer"),
    Some(Selected("Yes")),
  )
  assert_eq(bytes[:source.length()].to_owned(), source)
  assert_true(
    try {
      ignore(f.fill({ "answer": Selected("unknown") }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(f.fill({ "answer": Checked(true) }))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(f.fill({ "answer": Selected("No") }), bytes)
}

///|
test "nested selector keys are scoped and duplicate selectors are rejected" {
  assert_eq(
    values_from_text("{\"a\":{\"select\":\"Yes\"},\"b\":{\"select\":\"No\"}}").length(),
    2,
  )
  assert_true(
    try {
      ignore(values_from_text("{\"a\":{\"select\":\"Yes\",\"select\":\"No\"}}"))
      false
    } catch {
      _ => true
    },
  )
}
