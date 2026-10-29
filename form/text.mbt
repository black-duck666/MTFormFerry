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
  list_options~ : Array[String] = [],
  list_indices~ : Array[Int32] = [],
  fit_text~ : Bool = false,
) -> Unit raise {
  let multiline = !choice && (control.flags & 4096) != 0
  let comb = !choice && (control.flags & 16777216) != 0
  let alignment = if choice { 0 } else { text_alignment(doc, control) }
  guard (
      choice &&
      (
        (
          control.info.kind == Dropdown &&
          control.flags >= 131072 &&
          (control.flags & 131079) == control.flags
        ) ||
        (
          control.info.kind == Listbox &&
          control.flags >= 0 &&
          (control.flags & 2097159) == control.flags
        )
      )
    ) ||
    (
      !choice &&
      control.flags >= 0 &&
      (if comb {
        (control.flags & 16777223) == control.flags
      } else {
        (control.flags & 4103) == control.flags
      })
    ) else {
    fail(control.info.name + ": unsupported plain text flags")
  }
  guard value.length() <= 4096 &&
    value
    .iter()
    .all(c => {
      (c.to_int() >= 32 && c.to_int() <= 126) || (multiline && c == '\n')
    }) else {
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
  let cells = if comb {
    guard inherited(doc, control.object, "MaxLen") is Some(PdfInteger(n)) &&
      n > 0 &&
      n <= 4096 else {
      fail(control.info.name + ": Comb requires MaxLen in 1..4096")
    }
    n
  } else {
    0
  }
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
    let drawing = if control.info.kind == Listbox {
      let drawing = list_drawing(
        list_options, list_indices, width, height, size,
      ) catch {
        e => fail(control.info.name + ": " + e.to_string())
      }
      drawing
    } else {
      let (size, operators) = try {
        if comb {
          comb_layout(value, cells, width, size, alignment, fit_text)
        } else {
          fitted_layout(
            value,
            width,
            height,
            size,
            multiline,
            alignment,
            fit_text && !choice,
          )
        }
      } catch {
        e => fail(control.info.name + ": " + e.to_string())
      }
      "BT /FormFerryCourier \{size} Tf 0 g \{operators} ET"
    }
    let content = @utf8.encode("q 0 0 \{width} \{height} re W n \{drawing} Q\n")
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

///|
fn text_alignment(doc : @pdf.PdfDocument, c : Control) -> Int32 raise {
  let q = match inherited(doc, c.object, "Q") {
    Some(v) => Some(v)
    None =>
      match get(doc, doc.catalog(), "AcroForm") {
        Some(acro) => get(doc, acro, "Q")
        None => None
      }
  }
  match q {
    None => 0
    Some(PdfInteger(n)) if n >= 0 && n <= 2 => n
    _ => fail(c.info.name + ": Q must be 0 (left), 1 (center) or 2 (right)")
  }
}
