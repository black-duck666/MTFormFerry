///|
fn text_fixture() -> Bytes raise {
  let doc = @pdf.pdf_read_document_from_bytes(fixture())
  let obj = @syntax.PdfDictionary([
    (name("Type"), PdfNameObject(name("Annot"))),
    (name("Subtype"), PdfNameObject(name("Widget"))),
    (name("FT"), PdfNameObject(name("Tx"))),
    (name("T"), PdfString(b"customer")),
    (
      name("Rect"),
      PdfArray([PdfInteger(20), PdfInteger(60), PdfInteger(250), PdfInteger(90)]),
    ),
    (name("MaxLen"), PdfInteger(30)),
  ])
  doc.add_object_given_number(8, obj)
  doc.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(8)]))]),
  )
  let page = doc.direct(PdfIndirect(3))
  doc.add_object_given_number(
    3,
    page.replace_dict_entry(
      name("Annots"),
      PdfArray([PdfIndirect(5), PdfIndirect(8)]),
    ),
  )
  @pdf.pdf_write_document(doc)
}

///|
test "text appearance, escaping, readback and stable map order" {
  let input = text_fixture()
  let form = Form::open(input)
  let bytes = form.fill({
    "customer": Text("A (B) \\"),
    "approved": Checked(true),
  })
  assert_eq(
    bytes,
    form.fill({ "approved": Checked(true), "customer": Text("A (B) \\") }),
  )
  let filled = Form::open(bytes)
  let field = filled.controls[1]
  assert_eq(
    get(filled.document, field.object, "V"),
    Some(PdfString(b"A (B) \\")),
  )
  let ap = get(filled.document, field.widgets[0].1, "AP").unwrap()
  let appearance = get(filled.document, ap, "N").unwrap()
  let operators = @utf8.decode(appearance.stream_bytes())
  assert_true(operators.contains("A \\(B\\) \\\\"))
  assert_eq(bytes[:input.length()].to_owned(), input)
}

///|
test "text rejects missing glyphs, multiline, long values and recovers" {
  let form = Form::open(text_fixture())
  for invalid in ["中文", "a\nb", "x".repeat(31)] {
    assert_true(
      try {
        ignore(form.fill({ "customer": Text(invalid) }))
        false
      } catch {
        _ => true
      },
    )
  }
  ignore(form.fill({ "customer": Text("Grace") }))
}

///|
test "reject layout overflow and unsupported text flags" {
  let doc = @pdf.pdf_read_document_from_bytes(text_fixture())
  let obj = doc.direct(PdfIndirect(8))
  doc.add_object_given_number(
    8,
    obj.replace_dict_entry(
      name("Rect"),
      PdfArray([PdfInteger(0), PdfInteger(0), PdfInteger(10), PdfInteger(20)]),
    ),
  )
  let form = Form::open(@pdf.pdf_write_document(doc))
  assert_true(
    try {
      ignore(form.fill({ "customer": Text("AB") }))
      false
    } catch {
      _ => true
    },
  )
  doc.add_object_given_number(
    8,
    obj.add_dict_entry(name("Ff"), PdfInteger(8192)),
  )
  let form = Form::open(@pdf.pdf_write_document(doc))
  assert_true(
    try {
      ignore(form.fill({ "customer": Text("AB") }))
      false
    } catch {
      _ => true
    },
  )
}
