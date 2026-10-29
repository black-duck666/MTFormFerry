///|
fn fixture() -> Bytes {
  let objects = [
    "<< /Type /Catalog /Pages 2 0 R /AcroForm 4 0 R >>", "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 200] /Annots [5 0 R] >>", "<< /Fields [5 0 R] >>",
    "<< /Type /Annot /Subtype /Widget /FT /Btn /T (approved) /Rect [20 20 40 40] /V /Off /AS /Off /AP << /N << /Off 6 0 R /Yes 7 0 R >> >> >>",
    "<< /Type /XObject /Subtype /Form /BBox [0 0 20 20] /Length 0 >> stream\n\nendstream",
    "<< /Type /XObject /Subtype /Form /BBox [0 0 20 20] /Length 16 >> stream\n0 0 m 20 20 l S\n\nendstream",
  ]
  let output = StringBuilder()
  output.write_string("%PDF-1.4\n")
  let offsets = []
  for i, obj in objects {
    offsets.push(@utf8.encode(output.to_string()).length())
    output.write_string("\{i+1} 0 obj\n\{obj}\nendobj\n")
  }
  let xref = @utf8.encode(output.to_string()).length()
  output.write_string("xref\n0 8\n0000000000 65535 f \n")
  for offset in offsets {
    let decimal = offset.to_string()
    output.write_string(
      "0".repeat(10 - decimal.length()) + decimal + " 00000 n \n",
    )
  }
  output.write_string(
    "trailer\n<< /Size 8 /Root 1 0 R >>\nstartxref\n\{xref}\n%%EOF\n",
  )
  @utf8.encode(output.to_string())
}

///|
test "checkbox fill and unfill preserves source and displays selected appearance" {
  let bytes = fixture()
  let form = Form::open(bytes)
  assert_eq(form.fields().length(), 1)
  let filled = form.fill({ "approved": Checked(true) })
  let reopened = Form::open(filled)
  let control = reopened.controls[0]
  assert_eq(
    get(reopened.document, control.object, "V"),
    Some(PdfNameObject(name("Yes"))),
  )
  assert_eq(
    get(reopened.document, control.widgets[0].1, "AS"),
    Some(PdfNameObject(name("Yes"))),
  )
  assert_eq(filled[:bytes.length()].to_owned(), bytes)
  let reset = Form::open(reopened.fill({ "approved": Checked(false) }))
  assert_eq(
    get(reset.document, reset.controls[0].object, "V"),
    Some(PdfNameObject(name("Off"))),
  )
  assert_eq(form.fill({ "approved": Checked(true) }), filled)
}

///|
test "rejected transaction can be followed by a valid fill" {
  let form = Form::open(fixture())
  assert_true(
    try {
      ignore(form.fill({ "missing": Checked(true) }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(form.fill({ "approved": Text("yes") }))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(Form::open(b"not a PDF"))
      false
    } catch {
      _ => true
    },
  )
  ignore(form.fill({ "approved": Checked(true) }))
}

///|
test "reject cyclic trees and inherited read-only controls" {
  let doc = @pdf.pdf_read_document_from_bytes(fixture())
  let field = doc.direct(PdfIndirect(5))
  doc.add_object_given_number(
    5,
    field.add_dict_entry(name("Kids"), PdfArray([PdfIndirect(5)])),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(doc)))
      false
    } catch {
      _ => true
    },
  )
  let doc = @pdf.pdf_read_document_from_bytes(fixture())
  let parent = @syntax.PdfDictionary([
    (name("T"), PdfString(b"group")),
    (name("Ff"), PdfInteger(1)),
    (name("Kids"), PdfArray([PdfIndirect(5)])),
  ])
  doc.add_object_given_number(8, parent)
  doc.add_object_given_number(
    4,
    PdfDictionary([(name("Fields"), PdfArray([PdfIndirect(8)]))]),
  )
  let form = Form::open(@pdf.pdf_write_document(doc))
  assert_eq(form.fields()[0].name, "group.approved")
  assert_true(form.fields()[0].read_only)
  assert_true(
    try {
      ignore(form.fill({ "group.approved": Checked(true) }))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "all widgets of one checkbox track the field value" {
  let doc = @pdf.pdf_read_document_from_bytes(fixture())
  let original = doc.direct(PdfIndirect(5))
  let widget = original
    .remove_dict_entry(name("T"))
    .remove_dict_entry(name("FT"))
  doc.add_object_given_number(8, widget)
  doc.add_object_given_number(9, widget.deep_copy())
  doc.add_object_given_number(
    5,
    PdfDictionary([
      (name("T"), PdfString(b"approved")),
      (name("FT"), PdfNameObject(name("Btn"))),
      (name("Kids"), PdfArray([PdfIndirect(8), PdfIndirect(9)])),
    ]),
  )
  let page = doc.direct(PdfIndirect(3))
  doc.add_object_given_number(
    3,
    page.replace_dict_entry(
      name("Annots"),
      PdfArray([PdfIndirect(8), PdfIndirect(9)]),
    ),
  )
  let form = Form::open(@pdf.pdf_write_document(doc))
  let result = Form::open(form.fill({ "approved": Checked(true) }))
  assert_eq(result.value("approved"), Some(Checked(true)))
  assert_eq(result.controls[0].widgets.length(), 2)
  for (_, w) in result.controls[0].widgets {
    assert_eq(get(result.document, w, "AS"), Some(PdfNameObject(name("Yes"))))
  }
}
