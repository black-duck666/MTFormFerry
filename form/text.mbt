///|
fn number(obj : @syntax.PdfObject) -> Double raise {
  match obj {
    PdfInteger(i) => i.to_double()
    PdfReal(d) => d
    _ => fail("rectangle must contain numbers")
  }
}

///|
fn ascii_literal(s : String) -> String {
  let out = StringBuilder()
  for c in s {
    if c == '(' || c == ')' || c == '\\' {
      out.write_char('\\')
    }
    out.write_char(c)
  }
  out.to_string()
}

///|
fn fill_text(
  doc : @pdf.PdfDocument,
  control : Control,
  value : String,
  stored_value? : String,
  choice~ : Bool = false,
) -> Unit raise {
  guard (
      choice &&
      control.flags >= 131072 &&
      (control.flags & 131079) == control.flags
    ) ||
    (!choice && control.flags >= 0 && control.flags <= 7) else {
    fail(control.info.name + ": only plain single-line text is supported")
  }
  guard value.length() <= 4096 &&
    value.iter().all(c => c.to_int() >= 32 && c.to_int() <= 126) else {
    fail(
      control.info.name +
      ": text requires printable ASCII, at most 4096 characters",
    )
  }
  // MaxLen is inheritable through the parent field chain.
  let mut ancestor = control.object
  for depth in 0..<(if choice { 0 } else { 64 }) {
    if get(doc, ancestor, "MaxLen") is Some(limit) {
      guard limit is PdfInteger(n) && n >= value.length() else {
        fail(control.info.name + ": MaxLen exceeded or invalid")
      }
      break
    }
    match get(doc, ancestor, "Parent") {
      Some(p) => ancestor = p
      None => break
    }
    guard depth < 63 else { fail("cyclic Parent chain") }
  }
  let stored = @utf8.encode(stored_value.unwrap_or(value))
  let font = @syntax.PdfDictionary([
    (name("Type"), PdfNameObject(name("Font"))),
    (name("Subtype"), PdfNameObject(name("Type1"))),
    (name("BaseFont"), PdfNameObject(name("Courier"))),
  ])
  let font_number = doc.add_object(font)
  let resources = @syntax.PdfDictionary([
    (
      name("Font"),
      PdfDictionary([(name("FormFerryCourier"), PdfIndirect(font_number))]),
    ),
  ])
  // Each widget has its own measured size and appearance stream.
  for (id, widget) in control.widgets {
    guard get(doc, widget, "Subtype") == Some(PdfNameObject(name("Widget"))) else {
      fail(control.info.name + ": text needs Widget annotations")
    }
    if get(doc, widget, "MK") is Some(mk) {
      guard get(doc, mk, "R") is None ||
        get(doc, mk, "R") == Some(PdfInteger(0)) else {
        fail(control.info.name + ": rotated widget unsupported")
      }
    }
    guard get(doc, widget, "Rect") is Some(PdfArray(rect)) && rect.length() == 4 else {
      fail(control.info.name + ": invalid widget Rect")
    }
    let width = number(rect[2]) - number(rect[0])
    let height = number(rect[3]) - number(rect[1])
    guard width >= 8.0 &&
      height >= 10.0 &&
      width <= 10000.0 &&
      height <= 10000.0 else {
      fail(control.info.name + ": invalid widget dimensions")
    }
    let size = if height - 4.0 < 12.0 { height - 4.0 } else { 12.0 }
    guard value.length().to_double() * size * 0.6 <= width - 4.0 else {
      fail(control.info.name + ": text would overflow at the plain 12pt style")
    }
    let content = @utf8.encode(
      "q 0 0 \{width} \{height} re W n BT /FormFerryCourier \{size} Tf 0 g 2 3 Td (\{ascii_literal(value)}) Tj ET Q\n",
    )
    let stream = @syntax.pdf_stream(
      PdfDictionary([
        (name("Type"), PdfNameObject(name("XObject"))),
        (name("Subtype"), PdfNameObject(name("Form"))),
        (
          name("BBox"),
          PdfArray([
            PdfInteger(0),
            PdfInteger(0),
            PdfReal(width),
            PdfReal(height),
          ]),
        ),
        (name("Resources"), resources),
        (name("Length"), PdfInteger(content.length())),
      ]),
      StreamGot(content),
    )
    let ap = match get(doc, widget, "AP") {
      Some(a) => a
      None => PdfDictionary([])
    }
    guard get(doc, ap, "R") is None && get(doc, ap, "D") is None else {
      fail(control.info.name + ": rollover/down appearances unsupported")
    }
    let appearance = doc.add_object(stream)
    let updated = widget.add_dict_entry(
      name("AP"),
      ap.add_dict_entry(name("N"), PdfIndirect(appearance)),
    )
    let updated = if id == control.number {
      updated.add_dict_entry(name("V"), PdfString(stored))
    } else {
      updated
    }
    doc.add_object_given_number(id, updated)
  }
  if !control.widgets.any(pair => pair.0 == control.number) {
    doc.add_object_given_number(
      control.number,
      control.object.add_dict_entry(name("V"), PdfString(stored)),
    )
  }
}
