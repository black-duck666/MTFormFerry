///|
test "CSV typed records fill real controls with quoting and explicit empty text" {
  let f = Form::open(text_fixture())
  let rows = f.records_from_csv(
    "customer,approved\r\n\"A, \"\"B\"\"\",true\r\n,false\r\n",
  )
  assert_eq(rows.length(), 2)
  assert_eq(rows[0], { "customer": Text("A, \"B\""), "approved": Checked(true) })
  assert_eq(rows[1].get("customer"), Some(Text("")))
  let outputs = f.fill_batch(rows)
  assert_eq(Form::open(outputs[0]).value("customer"), Some(Text("A, \"B\"")))
  assert_eq(Form::open(outputs[1]).value("approved"), Some(Checked(false)))
  assert_eq(
    f.records_from_csv("customer\n spaced \n")[0].get("customer"),
    Some(Text(" spaced ")),
  )
  let choice = Form::open(dropdown_fixture())
  assert_eq(
    choice.records_from_csv("customer\nexp")[0].get("customer"),
    Some(Selected("exp")),
  )
  assert_eq(csv_rows("notes\n\"one\r\ntwo\"\n")[1][0], "one\r\ntwo")
  for
    value in [
      "",
      " ",
      "a,b",
      "a\"\"b",
      "one\ntwo",
      "one\r\ntwo",
      "(x)\\y",
      "x".repeat(4096),
    ] {
    let encoded = StringBuilder()
    encoded.write_string("customer\n\"")
    for ch in value {
      if ch == '"' {
        encoded.write_char('"')
      }
      encoded.write_char(ch)
    }
    encoded.write_char('"')
    assert_eq(
      f.records_from_csv(encoded.to_string())[0].get("customer"),
      Some(Text(value)),
    )
  }
}

///|
test "CSV rejects ambiguous malformed and oversized input without skipping records" {
  let f = Form::open(text_fixture())
  for
    source in [
      "",
      "customer",
      "customer\n",
      "customer,customer\na,b",
      "missing\nx",
      ",approved\na,true",
      "approved\nyes",
      "approved\n",
      "customer,approved\nx",
      "customer\na,b",
      "customer\n\"unterminated",
      "customer\n\"x\"junk",
      "customer\na\"b",
      "customer\nx\ry",
      "customer\n中文",
      "customer\n" + "x".repeat(4097),
      "customer\n" + "x\n".repeat(33),
      "customer\n" + "x".repeat(1048576),
    ] {
    assert_true(
      try {
        ignore(f.records_from_csv(source))
        false
      } catch {
        _ => true
      },
      msg=source[:50].to_owned(),
    )
  }
  assert_eq(f.records_from_csv("customer\n" + "x\n".repeat(32)).length(), 32)
  ignore(f.fill_batch(f.records_from_csv("customer,approved\nAda,true")))
}
