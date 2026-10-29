///|
fn dropdown_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let field = d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("FT"), PdfNameObject(name("Ch")))
    .add_dict_entry(name("Ff"), PdfInteger(131072))
    .add_dict_entry(
      name("Opt"),
      PdfArray([
        PdfString(b"Standard"),
        PdfArray([PdfString(b"exp"), PdfString(b"Express")]),
      ]),
    )
  d.add_object_given_number(8, field)
  @pdf.pdf_write_document(d)
}

///|
test "dropdown stores export and renders label with correct index" {
  let source = dropdown_fixture()
  let f = Form::open(source)
  assert_eq(f.choices("customer"), ["Standard", "exp"])
  let bytes = f.fill({ "customer": Selected("exp") })
  let result = Form::open(bytes)
  assert_eq(result.value("customer"), Some(Selected("exp")))
  let field = result.controls[1]
  assert_eq(
    get(result.document, field.object, "I"),
    Some(PdfArray([PdfInteger(1)])),
  )
  let ap = get(result.document, field.object, "AP").unwrap()
  let stream = get(result.document, ap, "N").unwrap()
  assert_true(@utf8.decode(stream.stream_bytes()).contains("(Express) Tj"))
  assert_eq(
    Form::open(result.fill({ "customer": Selected("Standard") })).value(
      "customer",
    ),
    Some(Selected("Standard")),
  )
  assert_eq(bytes[:source.length()].to_owned(), source)
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
test "dropdown rejects duplicate options and editable flags" {
  let d = @pdf.pdf_read_document_from_bytes(dropdown_fixture())
  let field = d.direct(PdfIndirect(8))
  d.add_object_given_number(
    8,
    field.add_dict_entry(
      name("Opt"),
      PdfArray([PdfString(b"same"), PdfString(b"same")]),
    ),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_true(
    try {
      ignore(f.choices("customer"))
      false
    } catch {
      _ => true
    },
  )
  d.add_object_given_number(
    8,
    field.add_dict_entry(name("Ff"), PdfInteger(393216)),
  )
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
