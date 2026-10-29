///|
test "auto fit chooses the largest bounded candidate and retains the exact value" {
  let (size, operators) = fitted_layout(
    "1234567890", 40.0, 20.0, 12.0, false, 2, true,
  )
  assert_eq(size, 6.0)
  assert_true(operators.contains("(1234567890) Tj"))
  assert_eq(
    fitted_layout("AB", 100.0, 20.0, 12.0, false, 0, true),
    fitted_layout("AB", 100.0, 20.0, 12.0, false, 0, false),
  )
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(
      name("Rect"),
      PdfArray([PdfInteger(0), PdfInteger(0), PdfInteger(40), PdfInteger(20)]),
    ),
  )
  let source = @pdf.pdf_write_document(d)
  let f = Form::open(source)
  let values : Map[String, Value] = { "customer": Text("1234567890") }
  assert_true(
    try {
      ignore(f.fill(values))
      false
    } catch {
      _ => true
    },
  )
  let bytes = f.fill(values, fit_text=true)
  assert_eq(Form::open(bytes).value("customer"), Some(Text("1234567890")))
  assert_eq(bytes[:source.length()].to_owned(), source)
  assert_eq(bytes, f.fill(values, fit_text=true))
  assert_eq(f.fill_batch([values], fit_text=true)[0], bytes)
  assert_true(
    try {
      ignore(f.fill({ "customer": Text("12345678901") }, fit_text=true))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(f.fill({ "customer": Text("x".repeat(31)) }, fit_text=true))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(f.fill({ "customer": Text("中文") }, fit_text=true))
      false
    } catch {
      _ => true
    },
  )
  ignore(f.fill(values, fit_text=true))
}

///|
test "auto fit measures multiline height and every candidate preserves content" {
  let value = "a\nb\nc\nd"
  let (size, _) = fitted_layout(value, 100.0, 40.0, 12.0, true, 1, true)
  assert_eq(size, 7.5)
  assert_true(
    try {
      ignore(text_operators(value, 100.0, 40.0, size + 0.25, true))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        fitted_layout("a\nb\nc\nd\ne\nf", 100.0, 40.0, 12.0, true, 0, true),
      )
      false
    } catch {
      _ => true
    },
  )
  let f = Form::open(multiline_fixture())
  let values : Map[String, Value] = { "customer": Text("a\nb\nc\nd\ne\nf") }
  let bytes = f.fill(values, fit_text=true)
  assert_eq(Form::open(bytes).value("customer"), values.get("customer"))
  let normal : Map[String, Value] = { "customer": Text("Ada") }
  assert_eq(f.fill(normal), f.fill(normal, fit_text=true))
}
