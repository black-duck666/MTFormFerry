///|
fn export_name(n : @core.PdfName) -> String raise {
  let b = n.bytes()
  guard b.length() > 1 &&
    b[0] == b'/' &&
    b[1:].iter().all(c => c.to_int() >= 32 && c.to_int() <= 126) else {
    fail("unsupported non-ASCII export name")
  }
  @utf8.decode(b[1:].to_owned())
}

///|
fn radio_states(
  doc : @pdf.PdfDocument,
  c : Control,
) -> Array[(@core.PdfName, Int32, @syntax.PdfObject)] raise {
  guard c.flags >= 32768 && (c.flags & 49159) == c.flags else {
    fail(c.info.name + ": radio flags unsupported")
  }
  guard get(doc, c.object, "Opt") is None else {
    fail(c.info.name + ": radio Opt mapping unsupported")
  }
  let result = []
  let used : Map[String, Bool] = Map([])
  for (id, widget) in c.widgets {
    guard get(doc, widget, "AP") is Some(ap) &&
      get(doc, ap, "N") is Some(PdfDictionary(entries)) else {
      fail(c.info.name + ": radio needs state appearances")
    }
    let on = entries.filter(e => e.0 != name("Off"))
    guard on.length() == 1 && entries.any(e => e.0 == name("Off")) else {
      fail(c.info.name + ": ambiguous radio states")
    }
    for (_, appearance) in entries {
      guard doc.direct(appearance) is PdfStreamObject(_) else {
        fail(c.info.name + ": radio appearance is not a stream")
      }
    }
    let key = export_name(on[0].0)
    guard !used.contains(key) else {
      fail(c.info.name + ": repeated radio export state")
    }
    used[key] = true
    result.push((on[0].0, id, widget))
  }
  result
}

///|
/// Discover actual export values rather than guessing labels or widget positions.
pub fn Form::choices(self : Form, key : String) -> Array[String] raise {
  let matches = self.controls.filter(c => c.info.name == key)
  guard matches.length() == 1 else { fail("unknown field: " + key) }
  let c = matches[0]
  if c.info.kind == Dropdown {
    return dropdown_options(self.document, c).map(p => p.0)
  }
  guard c.info.kind == Radio else {
    fail(key + ": field has no supported choices")
  }
  let result = []
  for (state, _, _) in radio_states(self.document, c) {
    result.push(export_name(state))
  }
  result
}

///|
fn fill_radio(
  doc : @pdf.PdfDocument,
  c : Control,
  selected : String,
) -> Unit raise {
  let states = radio_states(doc, c)
  guard states.any(s => export_name(s.0) == selected) else {
    fail(c.info.name + ": unknown radio choice " + selected)
  }
  let selected_name = name(selected)
  doc.add_object_given_number(
    c.number,
    c.object.add_dict_entry(name("V"), PdfNameObject(selected_name)),
  )
  for (on, id, widget) in states {
    let updated = widget.add_dict_entry(
      name("AS"),
      PdfNameObject(if on == selected_name { on } else { name("Off") }),
    )
    let updated = if id == c.number {
      updated.add_dict_entry(name("V"), PdfNameObject(selected_name))
    } else {
      updated
    }
    doc.add_object_given_number(id, updated)
  }
}
