///|
fn checkbox(
  doc : @pdf.PdfDocument,
  control : Control,
  checked : Bool,
) -> Unit raise {
  let mut selected = name("Off")
  let states = []
  for (number, widget) in control.widgets {
    guard get(doc, widget, "AP") is Some(ap) &&
      get(doc, ap, "N") is Some(PdfDictionary(entries)) else {
      fail(control.info.name + ": checkbox needs existing normal appearances")
    }
    let on = entries.filter(pair => pair.0 != name("Off"))
    guard on.length() == 1 && entries.any(pair => pair.0 == name("Off")) else {
      fail(control.info.name + ": ambiguous checkbox appearance states")
    }
    for (_, appearance) in entries {
      guard doc.direct(appearance) is PdfStreamObject(_) else {
        fail(control.info.name + ": appearance state must be a stream")
      }
    }
    let state = if checked { on[0].0 } else { name("Off") }
    guard states.is_empty() || selected == state else {
      fail(control.info.name + ": inconsistent widget export values")
    }
    selected = state
    states.push(
      (number, widget.add_dict_entry(name("AS"), PdfNameObject(state))),
    )
  }
  let field = control.object.add_dict_entry(name("V"), PdfNameObject(selected))
  doc.add_object_given_number(control.number, field)
  for (number, widget) in states {
    let updated = if number == control.number {
      widget.add_dict_entry(name("V"), PdfNameObject(selected))
    } else {
      widget
    }
    doc.add_object_given_number(number, updated)
  }
}

///|
/// Return a new PDF. Errors never mutate this Form or its input bytes.
pub fn Form::fill(
  self : Form,
  values : Map[String, Value],
  complete~ : Bool = false,
  fit_text~ : Bool = false,
) -> Bytes raise {
  let doc = @pdf.pdf_read_document_from_bytes(self.original)
  for key, _ in values {
    guard self.controls.any(c => c.info.name == key) else {
      fail("unknown field: " + key)
    }
  }
  for control in self.controls {
    let key = control.info.name
    guard values.get(key) is Some(value) else { continue }
    let candidates = self.controls.filter(c => c.info.name == key)
    guard candidates.length() == 1 else { fail("unknown field: " + key) }
    let control = candidates[0]
    guard !control.info.read_only else { fail(key + ": field is read-only") }
    match (control.info.kind, value) {
      (Checkbox, Checked(b)) => checkbox(doc, control, b)
      (Text, Text(s)) => fill_text(doc, control, s, fit_text~)
      (Radio, Selected(s)) => fill_radio(doc, control, s)
      (Dropdown | Listbox, Selected(s)) => fill_dropdown(doc, control, s)
      _ => fail(key + ": unsupported field/value combination")
    }
  }
  let bytes = @pdf.pdf_write_document_incremental_update(self.original, doc)
  if complete {
    let missing = Form::open(bytes).missing_required()
    guard missing.is_empty() else {
      fail("missing required fields: " + missing.join(", "))
    }
  }
  bytes
}
