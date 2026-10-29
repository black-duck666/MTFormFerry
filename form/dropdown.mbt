///|
fn inherited(
  doc : @pdf.PdfDocument,
  object : @syntax.PdfObject,
  key : String,
) -> @syntax.PdfObject? raise {
  let mut obj = object
  for _ in 0..<64 {
    if get(doc, obj, key) is Some(v) {
      return Some(v)
    }
    match get(doc, obj, "Parent") {
      Some(p) => obj = p
      None => return None
    }
  }
  fail("Parent chain exceeds limit")
}

///|
fn dropdown_options(
  doc : @pdf.PdfDocument,
  c : Control,
) -> Array[(String, String)] raise {
  guard (
      c.info.kind == Dropdown &&
      c.flags >= 131072 &&
      (c.flags & 131079) == c.flags
    ) ||
    (c.info.kind == Listbox && c.flags >= 0 && (c.flags & 7) == c.flags) else {
    fail(
      c.info.name +
      ": editable, sorted or multi-select choice flags unsupported",
    )
  }
  guard inherited(doc, c.object, "Opt") is Some(PdfArray(opts)) &&
    !opts.is_empty() &&
    opts.length() <= 4096 else {
    fail(c.info.name + ": missing or oversized Opt array")
  }
  let result = []
  let used : Map[String, Bool] = Map([])
  for entry in opts {
    let pair = match doc.direct(entry) {
      PdfString(_) as s => {
        let value = text(s)
        (value, value)
      }
      PdfArray(a) => {
        guard a.length() == 2 else {
          fail(c.info.name + ": option must have export and display strings")
        }
        (text(doc.direct(a[0])), text(doc.direct(a[1])))
      }
      _ => fail(c.info.name + ": invalid option")
    }
    guard !pair.0.is_empty() && !used.contains(pair.0) else {
      fail(c.info.name + ": empty or repeated option export")
    }
    used[pair.0] = true
    result.push(pair)
  }
  result
}

///|
fn fill_dropdown(
  doc : @pdf.PdfDocument,
  c : Control,
  selected : String,
) -> Unit raise {
  let options = dropdown_options(doc, c)
  let mut index = -1
  for i, pair in options {
    if pair.0 == selected {
      index = i
    }
  }
  guard index >= 0 else {
    fail(c.info.name + ": unknown dropdown choice " + selected)
  }
  fill_text(
    doc,
    c,
    options[index].1,
    stored_value=selected,
    choice=true,
    list_options=if c.info.kind == Listbox { options.map(p => p.1) } else { [] },
    list_index=index,
  )
  let field = doc.direct(PdfIndirect(c.number))
  doc.add_object_given_number(
    c.number,
    if c.info.kind == Listbox {
      field
      .add_dict_entry(name("I"), PdfArray([PdfInteger(index)]))
      .add_dict_entry(name("TI"), PdfInteger(0))
    } else {
      field.add_dict_entry(name("I"), PdfArray([PdfInteger(index)]))
    },
  )
}
