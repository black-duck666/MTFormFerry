///|
test "alignment measures single lines and each wrapped line without changing values" {
  assert_eq(text_operators("AB", 100.0, 20.0, 10.0, false), "2 3 Td (AB) Tj")
  assert_eq(
    text_operators("AB", 100.0, 20.0, 10.0, false, alignment=1),
    "44 3 Td (AB) Tj",
  )
  assert_eq(
    text_operators("AB", 100.0, 20.0, 10.0, false, alignment=2),
    "86 3 Td (AB) Tj",
  )
  assert_eq(
    text_operators("AB\nX", 100.0, 50.0, 10.0, true, alignment=1),
    "1 0 0 1 44 38 Tm (AB) Tj 1 0 0 1 47 26 Tm (X) Tj ",
  )
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let field = d.direct(PdfIndirect(8))
  for q in [0, 1, 2] {
    d.add_object_given_number(8, field.add_dict_entry(name("Q"), PdfInteger(q)))
    let f = Form::open(@pdf.pdf_write_document(d))
    let bytes = f.fill({ "customer": Text("Ada") })
    assert_eq(Form::open(bytes).value("customer"), Some(Text("Ada")))
    assert_eq(bytes, f.fill({ "customer": Text("Ada") }))
  }
}

///|
test "alignment inherits from parents and form defaults and rejects malformed Q" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let field = d.direct(PdfIndirect(8))
  d.add_object_given_number(
    4,
    d.direct(PdfIndirect(4)).add_dict_entry(name("Q"), PdfInteger(1)),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_eq(text_alignment(f.document, f.controls[1]), 1)
  d.add_object_given_number(
    8,
    field.add_dict_entry(name("Parent"), PdfIndirect(9)),
  )
  d.add_object_given_number(
    9,
    PdfDictionary([
      (name("T"), PdfString(b"group")),
      (name("Q"), PdfInteger(2)),
      (name("Kids"), PdfArray([PdfIndirect(8)])),
    ]),
  )
  d.add_object_given_number(
    4,
    d
    .direct(PdfIndirect(4))
    .add_dict_entry(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(9)])),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  assert_eq(text_alignment(f.document, f.controls[1]), 2)
  for
    q in [
      @syntax.PdfObject::PdfInteger(-1),
      PdfInteger(3),
      PdfString(b"center"),
    ] {
    d.add_object_given_number(8, field.add_dict_entry(name("Q"), q))
    let f = Form::open(@pdf.pdf_write_document(d))
    assert_true(
      try {
        ignore(f.fill({ "group.customer": Text("Ada") }))
        false
      } catch {
        _ => true
      },
    )
  }
  ignore(Form::open(text_fixture()).fill({ "customer": Text("Ada") }))
}
