///|
fn selection_indices(
  c : Control,
  options : Array[(String, String)],
  selected : Array[String],
) -> Array[Int32] raise {
  guard selected.length() <= options.length() else {
    fail(c.info.name + ": too many selections")
  }
  let result = []
  let mut previous = -1
  for s in selected {
    let mut index = -1
    for i, option in options {
      if option.0 == s {
        index = i
      }
    }
    guard index > previous else {
      fail(
        c.info.name + ": choices must be distinct known exports in option order",
      )
    }
    result.push(index)
    previous = index
  }
  result
}

///|
fn fill_multi(
  doc : @pdf.PdfDocument,
  c : Control,
  selected : Array[String],
) -> Unit raise {
  guard c.info.kind == Listbox && (c.flags & 2097152) != 0 else {
    fail(c.info.name + ": Selections requires a multi-select list")
  }
  let options = dropdown_options(doc, c)
  let indices = selection_indices(c, options, selected)
  if selected.is_empty() {
    reject_inherited_clear(doc, c)
  }
  fill_text(
    doc,
    c,
    "",
    choice=true,
    list_options=options.map(p => p.1),
    list_indices=indices,
  )
  let field = doc
    .direct(PdfIndirect(c.number))
    .add_dict_entry(name("TI"), PdfInteger(0))
  let field = if selected.is_empty() {
    field.remove_dict_entry(name("V")).remove_dict_entry(name("I"))
  } else {
    field
    .add_dict_entry(
      name("V"),
      PdfArray(selected.map(s => @syntax.PdfObject::PdfString(@utf8.encode(s)))),
    )
    .add_dict_entry(
      name("I"),
      PdfArray(indices.map(i => @syntax.PdfObject::PdfInteger(i))),
    )
  }
  doc.add_object_given_number(c.number, field)
}

///|
fn reject_inherited_clear(doc : @pdf.PdfDocument, c : Control) -> Unit raise {
  if get(doc, c.object, "Parent") is Some(parent) {
    guard inherited(doc, parent, "V") is None else {
      fail(c.info.name + ": clearing an inherited choice value is unsupported")
    }
  }
}

///|
fn json_selections(input : Json, key : String) -> Array[String] raise {
  guard input is Array(a) && a.length() <= 4096 else {
    fail(key + ": select needs an array of at most 4096 strings")
  }
  let result = []
  let seen : Map[String, Bool] = Map([])
  for item in a {
    guard item is String(s) && !seen.contains(s) else {
      fail(key + ": selections must be distinct strings")
    }
    seen[s] = true
    result.push(s)
  }
  result
}

///|
fn matches_value(expected : Value, actual : Value?) -> Bool {
  actual == Some(expected) ||
  (expected is Selections(s) && s.is_empty() && actual is None)
}
