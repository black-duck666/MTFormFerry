///|
test "value snapshot is deterministic and roundtrips escaped values" {
  let f = Form::open(text_fixture())
  let data : Map[String, Value] = {
    "customer": Text("A (B) \\\""),
    "approved": Checked(true),
  }
  let filled = Form::open(f.fill(data))
  let snapshot = filled.values_json().stringify()
  assert_eq(values_from_text(snapshot), data)
  assert_eq(snapshot, filled.values_json().stringify())
  assert_eq(
    Form::open(f.fill(values_from_text(snapshot))).values_json().stringify(),
    snapshot,
  )
  assert_eq(
    Form::open(text_fixture()).values_json().stringify(),
    "{\"approved\":false}",
  )
  let choice = Form::open(
    Form::open(dropdown_fixture()).fill({ "customer": Selected("exp") }),
  )
  assert_eq(
    values_from_json(choice.values_json()).get("customer"),
    Some(Selected("exp")),
  )
}

///|
test "snapshot refuses unknown data and contradictory appearances" {
  let d = @pdf.pdf_read_document_from_bytes(fixture())
  let original = d.direct(PdfIndirect(5))
  for
    bad in [
      original.add_dict_entry(name("V"), PdfNameObject(name("Other"))),
      original.add_dict_entry(name("V"), PdfNameObject(name("Yes"))),
      original
      .add_dict_entry(name("FT"), PdfNameObject(name("Unknown")))
      .remove_dict_entry(name("V")),
    ] {
    d.add_object_given_number(5, bad)
    assert_true(
      try {
        ignore(Form::open(@pdf.pdf_write_document(d)).values_json())
        false
      } catch {
        _ => true
      },
    )
  }
  ignore(Form::open(fixture()).values_json())
}
