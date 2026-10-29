///|
test "FDF values roundtrip escaped text checkbox and selections deterministically" {
  let template = Form::open(text_fixture())
  let values : Map[String, Value] = {
    "customer": Text("A (B) \\"),
    "approved": Checked(true),
  }
  let filled = Form::open(template.fill(values))
  let fdf = filled.values_fdf()
  assert_eq(fdf[:8].to_owned(), b"%FDF-1.2")
  assert_eq(template.values_from_fdf(fdf), values)
  assert_eq(fdf, filled.values_fdf())
  assert_eq(
    Form::open(template.fill(template.values_from_fdf(fdf))).values_fdf(),
    fdf,
  )
  let choice = Form::open(multi_fixture())
  let done = Form::open(
    choice.fill({ "customer": Selections(["Standard", "exp"]) }),
  )
  assert_eq(
    choice.values_from_fdf(done.values_fdf()).get("customer"),
    Some(Selections(["Standard", "exp"])),
  )
}

///|
test "FDF nested field names preserve hierarchy and type checking" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  d.add_object_given_number(
    8,
    d.direct(PdfIndirect(8)).add_dict_entry(name("Parent"), PdfIndirect(9)),
  )
  d.add_object_given_number(
    9,
    PdfDictionary([
      (name("T"), PdfString(b"group")),
      (name("Kids"), PdfArray([PdfIndirect(8)])),
    ]),
  )
  d.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(5), PdfIndirect(9)]))]),
  )
  let f = Form::open(@pdf.pdf_write_document(d))
  let done = Form::open(f.fill({ "group.customer": Text("Ada") }))
  assert_eq(
    f.values_from_fdf(done.values_fdf()).get("group.customer"),
    Some(Text("Ada")),
  )
  let radio = Form::open(
    Form::open(radio_fixture()).fill({ "answer": Selected("No") }),
  )
  assert_eq(
    Form::open(radio_fixture())
    .values_from_fdf(radio.values_fdf())
    .get("answer"),
    Some(Selected("No")),
  )
}

///|
test "FDF rejects foreign fields extra attributes malformed and duplicate assignments" {
  let f = Form::open(text_fixture())
  let done = Form::open(f.fill({ "customer": Text("Ada") }))
  let good = done.values_fdf()
  let d = @pdf.pdf_read_classic_document_from_bytes(
    fdf_header(good, b"%PDF-1.2"),
  )
  let root = d.root()
  let field = @syntax.PdfDictionary([
    (name("T"), PdfString(b"customer")),
    (name("V"), PdfString(b"Ada")),
  ])
  for
    fields in [
      [field, field],
      [field.add_dict_entry(name("AP"), PdfDictionary([]))],
      [field.add_dict_entry(name("T"), PdfString(b"missing"))],
      [field.remove_dict_entry(name("V"))],
      [field.add_dict_entry(name("V"), PdfInteger(1))],
    ] {
    d.add_object_given_number(
      root,
      PdfDictionary([
        (name("FDF"), PdfDictionary([(name("Fields"), PdfArray(fields))])),
      ]),
    )
    let bad = fdf_header(@pdf.pdf_write_document(d), b"%FDF-1.2")
    assert_true(
      try {
        ignore(f.values_from_fdf(bad))
        false
      } catch {
        _ => true
      },
    )
  }
  for bad in [b"not FDF", fdf_header(good, b"%FDF-1.3"), good[:30].to_owned()] {
    assert_true(
      try {
        ignore(f.values_from_fdf(bad))
        false
      } catch {
        _ => true
      },
    )
  }
  assert_eq(f.values_from_fdf(good).get("customer"), Some(Text("Ada")))
}
