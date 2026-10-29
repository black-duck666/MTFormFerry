///|
test "public JSON selections distinguish arrays from single choices" {
  let values = @form.values_from_text(
    "{\"materials\":{\"select\":[\"README\",\"examples\"]}}",
  )
  assert_eq(
    values.get("materials"),
    Some(@form.Value::Selections(["README", "examples"])),
  )
  for
    text in [
      "{\"x\":{\"select\":[\"a\",\"a\"]}}", "{\"x\":{\"select\":[1]}}", "{\"x\":{\"select\":null}}",
    ] {
    assert_true(
      try {
        ignore(@form.values_from_text(text))
        false
      } catch {
        _ => true
      },
    )
  }
}
