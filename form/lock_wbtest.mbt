///|
test "locking completed fields preserves appearances values and original bytes" {
  let f = Form::open(
    Form::open(text_fixture()).fill({
      "customer": Text("Ada"),
      "approved": Checked(true),
    }),
  )
  let bytes = f.lock(["customer"])
  let locked = Form::open(bytes)
  assert_true(locked.fields()[1].read_only)
  assert_false(locked.fields()[0].read_only)
  assert_eq(locked.value("customer"), Some(Text("Ada")))
  assert_eq(
    get(f.document, f.controls[1].object, "AP"),
    get(locked.document, locked.controls[1].object, "AP"),
  )
  assert_eq(bytes[:f.original.length()].to_owned(), f.original)
  assert_eq(locked.lock(["customer"]), bytes)
  assert_true(
    try {
      ignore(locked.fill({ "customer": Text("Grace") }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(locked.reset(["customer"]))
      false
    } catch {
      _ => true
    },
  )
  ignore(f.fill({ "customer": Text("Grace") }))
}

///|
test "locking retains comb and multi flags and is deterministic across name order" {
  let f = Form::open(comb_fixture())
  let a = f.lock(["customer", "approved"])
  assert_eq(a, f.lock(["approved", "customer"]))
  assert_eq(Form::open(a).controls[1].flags, 16777217)
  let f = Form::open(multi_fixture())
  assert_eq(Form::open(f.lock(["customer"])).controls[1].flags, 2097155)
}

///|
test "locking validates names and optionally refuses incomplete forms" {
  let f = Form::open(required_fixture())
  for
    fields in [
      [],
      ["missing"],
      ["customer", "customer"],
      ["approved", "missing"],
    ] {
    assert_true(
      try {
        ignore(f.lock(fields))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(f.lock(["customer"], complete=true))
      false
    } catch {
      _ => true
    },
  )
  let done = Form::open(
    f.fill({ "customer": Text("Ada"), "approved": Checked(true) }),
  )
  assert_true(
    Form::open(done.lock(["customer"], complete=true)).fields()[1].read_only,
  )
  assert_eq(f.missing_required(), ["approved", "customer"])
}
