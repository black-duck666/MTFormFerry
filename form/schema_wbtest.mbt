///|
test "schema exposes true export label mapping and text constraints in source order" {
  let f = Form::open(dropdown_fixture())
  guard f.schema_json()
    is { "version": Number(1.0, ..), "fields": Array(fields), .. } else {
    fail("invalid schema")
  }
  assert_eq(fields.length(), 2)
  assert_true(
    fields[1]
    is {
      "name": String("customer"),
      "options": Array(
        [_, { "export": String("exp"), "label": String("Express"), .. }]
      ),
      ..
    },
  )
  assert_eq(f.schema_json().stringify(), f.schema_json().stringify())
  guard Form::open(comb_fixture()).schema_json()
    is { "fields": Array([_, comb]), .. } else {
    fail("missing comb")
  }
  assert_true(
    comb
    is {
      "comb": True,
      "max_length": Number(8.0, ..),
      "alignment": String("left"),
      ..
    },
  )
}

///|
test "schema keeps unsupported fields and refuses misleading malformed options" {
  let d = @pdf.pdf_read_document_from_bytes(text_fixture())
  let original = d.direct(PdfIndirect(8))
  d.add_object_given_number(
    8,
    original.add_dict_entry(name("FT"), PdfNameObject(name("Custom"))),
  )
  guard Form::open(@pdf.pdf_write_document(d)).schema_json()
    is { "fields": Array([_, unsupported]), .. } else {
    fail("field was dropped")
  }
  assert_true(
    unsupported
    is {
      "supported": False,
      "writable": False,
      "kind": String("unsupported"),
      ..
    },
  )
  d.add_object_given_number(
    8,
    original.add_dict_entry(name("MaxLen"), PdfInteger(-1)),
  )
  assert_true(
    try {
      ignore(Form::open(@pdf.pdf_write_document(d)).schema_json())
      false
    } catch {
      _ => true
    },
  )
}
