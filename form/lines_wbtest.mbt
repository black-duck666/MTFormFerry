///|
fn multiline_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let field = d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("Ff"), PdfInteger(4096))
    .add_dict_entry(
      name("Rect"),
      PdfArray([
        PdfInteger(20),
        PdfInteger(20),
        PdfInteger(100),
        PdfInteger(100),
      ]),
    )
  d.add_object_given_number(8, field)
  @pdf.pdf_write_document(d)
}

///|
test "multiline preserves stored LF and uses measured hard wrapping" {
  let f = Form::open(multiline_fixture())
  let value = "first line\nsecond (line)"
  let result = Form::open(f.fill({ "customer": Text(value) }))
  assert_eq(result.value("customer"), Some(Value::Text(value)))
  let ap = get(result.document, result.controls[1].object, "AP").unwrap()
  let operators = @utf8.decode(
    get(result.document, ap, "N").unwrap().stream_bytes(),
  )
  assert_true(operators.contains("(first line) Tj"))
  assert_true(operators.contains("(second \\(li) Tj"))
  assert_true(operators.contains("(ne\\)) Tj"))
  assert_true(
    try {
      ignore(f.fill({ "customer": Text("x\nx\nx\nx\nx\nx") }))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(
    Form::open(f.fill({ "customer": Text("") })).value("customer"),
    Some(Value::Text("")),
  )
}

///|
test "line wrapping preserves every space and rejects insufficient height" {
  assert_eq(
    text_operators("ab cd", 25.6, 50.0, 12.0, true),
    "1 0 0 1 2 36 Tm (ab ) Tj 1 0 0 1 2 21.6 Tm (cd) Tj ",
  )
  assert_true(
    try {
      ignore(text_operators("a\nb", 100.0, 20.0, 12.0, true))
      false
    } catch {
      _ => true
    },
  )
}
