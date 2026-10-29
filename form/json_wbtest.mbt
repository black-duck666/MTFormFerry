///|
test "JSON boundary and public value readback" {
  let f = Form::open(text_fixture())
  let values = values_from_json({ "customer": "FormFerry", "approved": true })
  let result = Form::open(f.fill(values))
  assert_eq(result.value("customer"), Some(Value::Text("FormFerry")))
  assert_eq(result.value("approved"), Some(Checked(true)))
  for
    bad in [
      Json::null(),
      Json::array([]),
      { "customer": 123 },
      { "approved": null },
    ] {
    assert_true(
      try {
        ignore(values_from_json(bad))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "raw JSON rejects duplicate escaped names and malformed inputs" {
  for
    source in [
      "{\"a\":true,\"a\":false}", "{\"a\":true,\"\\u0061\":false}", "{\"a\":", "{\"a\":{\"b\":true}}",
    ] {
    assert_true(
      try {
        ignore(values_from_text(source))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(
    values_from_text("{\"a\":\"a\\\"b\",\"b\":false}")["a"],
    Value::Text("a\"b"),
  )
}
