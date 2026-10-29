///|
fn multi_fixture() -> Bytes raise {
  let d = @pdf.pdf_read_document_from_bytes(list_fixture())
  d.add_object_given_number(
    8,
    d.direct(PdfIndirect(8)).add_dict_entry(name("Ff"), PdfInteger(2097154)),
  )
  @pdf.pdf_write_document(d)
}

///|
test "multi selection synchronizes arrays highlights and snapshot round trips" {
  let source = multi_fixture()
  let f = Form::open(source)
  let values : Map[String, Value] = {
    "customer": Selections(["Standard", "exp"]),
  }
  let bytes = f.fill(values, complete=true)
  let result = Form::open(bytes)
  assert_eq(result.value("customer"), values.get("customer"))
  assert_eq(
    values_from_json(result.values_json()).get("customer"),
    values.get("customer"),
  )
  let c = result.controls[1]
  assert_eq(
    get(result.document, c.object, "I"),
    Some(PdfArray([PdfInteger(0), PdfInteger(1)])),
  )
  assert_eq(
    get(result.document, c.object, "V"),
    Some(PdfArray([PdfString(b"Standard"), PdfString(b"exp")])),
  )
  let ap = get(result.document, c.widgets[0].1, "AP").unwrap()
  let operators = @utf8.decode(
    get(result.document, ap, "N").unwrap().stream_bytes(),
  )
  assert_eq(operators.split("0.85 g").to_array().length(), 3)
  assert_eq(bytes[:source.length()].to_owned(), source)
  assert_eq(bytes, f.fill(values))
  assert_eq(f.fill_batch([values], complete=true)[0], bytes)
  assert_eq(
    Form::open(result.fill({ "customer": Selections(["exp"]) })).value(
      "customer",
    ),
    Some(Selections(["exp"])),
  )
  let csv = "customer\n\"[\"\"Standard\"\",\"\"exp\"\"]\""
  assert_eq(f.fill_batch(f.records_from_csv(csv))[0], bytes)
}

///|
test "multi selection clearing updates appearances and enforces required policy" {
  let f = Form::open(
    Form::open(multi_fixture()).fill({ "customer": Selections(["exp"]) }),
  )
  let cleared = Form::open(f.fill({ "customer": Selections([]) }))
  assert_eq(cleared.value("customer"), None)
  assert_eq(cleared.missing_required(), ["customer"])
  assert_true(get(cleared.document, cleared.controls[1].object, "I") is None)
  let ap = get(cleared.document, cleared.controls[1].object, "AP").unwrap()
  assert_false(
    @utf8.decode(get(cleared.document, ap, "N").unwrap().stream_bytes()).contains(
      "0.85 g",
    ),
  )
  assert_true(
    try {
      ignore(f.fill({ "customer": Selections([]) }, complete=true))
      false
    } catch {
      _ => true
    },
  )
  ignore(f.fill_batch([{ "customer": Selections([]) }]))
  assert_eq(f.value("customer"), Some(Selections(["exp"])))
}

///|
test "multi selection refuses ambiguity and invalid current indices without reordering" {
  let f = Form::open(multi_fixture())
  for
    s in [
      ["exp", "Standard"],
      ["exp", "exp"],
      ["missing"],
      ["Standard", "exp", "extra"],
    ] {
    assert_true(
      try {
        ignore(f.fill({ "customer": Selections(s) }))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_true(
    try {
      ignore(f.fill({ "customer": Selected("exp") }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        Form::open(list_fixture()).fill({ "customer": Selections(["exp"]) }),
      )
      false
    } catch {
      _ => true
    },
  )
  let bytes = f.fill({ "customer": Selections(["Standard", "exp"]) })
  let d = @pdf.pdf_read_document_from_bytes(bytes)
  d.add_object_given_number(
    8,
    d
    .direct(PdfIndirect(8))
    .add_dict_entry(name("I"), PdfArray([PdfInteger(1), PdfInteger(0)])),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(d)).values_json())
      false
    } catch {
      _ => true
    },
  )
  ignore(f.fill({ "customer": Selections(["exp"]) }))
}
