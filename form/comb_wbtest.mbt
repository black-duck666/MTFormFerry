///|
fn comb_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("Ff"), PdfInteger(16777216))
    .add_dict_entry(name("MaxLen"), PdfInteger(8)),
  )
  @pdf.pdf_write_document(d)
}

///|
test "comb stores exact text and places each escaped glyph in a separate cell" {
  let f = Form::open(comb_fixture())
  let value = "A (B)\\"
  let bytes = f.fill({ "customer": Text(value) })
  let result = Form::open(bytes)
  assert_eq(result.value("customer"), Some(Text(value)))
  let ap = get(result.document, result.controls[1].object, "AP").unwrap()
  let operators = @utf8.decode(
    get(result.document, ap, "N").unwrap().stream_bytes(),
  )
  assert_eq(operators.split(" Tm ").to_array().length(), value.length() + 1)
  assert_true(operators.contains("(\\() Tj"))
  assert_eq(bytes, f.fill({ "customer": Text(value) }, fit_text=true))
  assert_eq(
    Form::open(f.fill({ "customer": Text("") })).value("customer"),
    Some(Text("")),
  )
  assert_true(
    try {
      ignore(f.fill({ "customer": Text("123456789") }))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "comb alignment fitting and invalid flags are explicit" {
  assert_true(comb_layout("A", 3, 64.0, 12.0, 0, false).1.contains("8.4 3 Tm"))
  assert_true(comb_layout("A", 3, 64.0, 12.0, 1, false).1.contains("28.4 3 Tm"))
  assert_true(comb_layout("A", 3, 64.0, 12.0, 2, false).1.contains("48.4 3 Tm"))
  assert_eq(comb_layout("12345678", 8, 40.0, 12.0, 0, true).0, 7.5)
  let d = @pdf.pdf_read_document_from_bytes(comb_fixture())
  let original = d.direct(PdfIndirect(8))
  for
    field in [
      original.remove_dict_entry(name("MaxLen")),
      original.add_dict_entry(name("MaxLen"), PdfInteger(0)),
      original.add_dict_entry(name("Ff"), PdfInteger(16781312)),
    ] {
    d.add_object_given_number(8, field)
    assert_true(
      try {
        ignore(
          Form::open(@pdf.pdf_write_document(d)).fill({ "customer": Text("A") }),
        )
        false
      } catch {
        _ => true
      },
    )
  }
  ignore(Form::open(comb_fixture()).fill({ "customer": Text("FORM2026") }))
}
