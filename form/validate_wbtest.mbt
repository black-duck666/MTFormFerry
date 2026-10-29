///|
test "preflight collects all errors deterministically and never poisons a fill" {
  let f = Form::open(text_fixture())
  let updates : Map[String, Value] = {
    "z": Text("x"),
    "customer": Text("x".repeat(31)),
    "approved": Text("wrong"),
    "a": Checked(true),
  }
  let issues = f.validate(updates)
  assert_eq(issues.map(i => i.field), ["approved", "customer", "a", "z"])
  assert_eq(
    issues,
    f.validate({
      "a": Checked(true),
      "approved": Text("wrong"),
      "customer": Text("x".repeat(31)),
      "z": Text("x"),
    }),
  )
  let good : Map[String, Value] = {
    "customer": Text("Ada"),
    "approved": Checked(true),
  }
  let baseline = f.fill(good)
  assert_eq(f.validate(good), [])
  assert_eq(f.fill(good), baseline)
}

///|
test "preflight required checks use candidate values and preserve draft behavior" {
  let f = Form::open(required_fixture())
  assert_eq(f.validate({}), [])
  assert_eq(f.validate({}, complete=true).map(i => i.field), [
    "approved", "customer",
  ])
  assert_eq(
    f.validate(
      { "approved": Checked(true), "customer": Text("Ada") },
      complete=true,
    ),
    [],
  )
  let issues = f.validate(
    { "approved": Text("bad"), "customer": Text(" ") },
    complete=true,
  )
  assert_eq(issues.length(), 2)
  assert_eq(issues[1].message, "required field is empty")
}
