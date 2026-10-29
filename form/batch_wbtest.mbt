///|
test "batch preserves record order, isolation and deterministic output" {
  let f = Form::open(text_fixture())
  let rows = records_from_text(
    "[{\"customer\":\"Ada\",\"approved\":true},{\"customer\":\"Grace\",\"approved\":false}]",
  )
  let bytes = f.fill_batch(rows)
  assert_eq(bytes.length(), 2)
  assert_eq(Form::open(bytes[0]).value("customer"), Some(Value::Text("Ada")))
  assert_eq(Form::open(bytes[1]).value("customer"), Some(Value::Text("Grace")))
  assert_eq(Form::open(bytes[0]).value("approved"), Some(Checked(true)))
  assert_eq(Form::open(bytes[1]).value("approved"), Some(Checked(false)))
  assert_eq(f.fill_batch(rows), bytes)
  assert_eq(f.value("customer"), None)
  assert_true(
    try {
      ignore(
        f.fill_batch([{ "customer": Text("Ada") }, { "missing": Checked(true) }]),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_eq(f.fill_batch(rows), bytes)
}

///|
test "batch refuses empty, oversized, malformed and duplicate-key records" {
  for input in ["[]", "{}", "[null]", "[{\"a\":true,\"a\":false}]"] {
    assert_true(
      try {
        ignore(records_from_text(input))
        false
      } catch {
        _ => true
      },
    )
  }
  let f = Form::open(fixture())
  assert_true(
    try {
      ignore(f.fill_batch([]))
      false
    } catch {
      _ => true
    },
  )
  let records : Array[Map[String, Value]] = Array::make(33, {
    "approved": Checked(true),
  })
  assert_true(
    try {
      ignore(f.fill_batch(records))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(
    f.fill_batch(Array::make(32, { "approved": Checked(true) })).length(),
    32,
  )
}
