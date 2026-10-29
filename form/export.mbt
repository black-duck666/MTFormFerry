///|
fn Form::checked_current(self : Form, c : Control) -> Value? raise {
  guard c.info.kind != Unsupported else {
    fail(c.info.name + ": cannot export unsupported control")
  }
  let value = self.value(c.info.name)
  match c.info.kind {
    Checkbox => {
      let expected = match inherited(self.document, c.object, "V") {
        None => name("Off")
        Some(PdfNameObject(n)) => n
        _ => fail(c.info.name + ": invalid checkbox value")
      }
      for (_, widget) in c.widgets {
        guard get(self.document, widget, "AP") is Some(ap) &&
          get(self.document, ap, "N") is Some(PdfDictionary(entries)) else {
          fail(c.info.name + ": checkbox needs state appearances")
        }
        guard entries.length() == 2 &&
          entries.any(p => p.0 == name("Off")) &&
          entries.any(p => p.0 == expected) &&
          entries.all(p => self.document.direct(p.1) is PdfStreamObject(_)) else {
          fail(c.info.name + ": invalid checkbox export state")
        }
        guard get(self.document, widget, "AS") == Some(PdfNameObject(expected)) else {
          fail(c.info.name + ": checkbox value and appearance disagree")
        }
      }
    }
    Radio => {
      let states = radio_states(self.document, c)
      let selected = match value {
        Some(Selected(s)) => s
        None => ""
        _ => fail(c.info.name + ": invalid radio value")
      }
      guard selected.is_empty() || states.any(s => export_name(s.0) == selected) else {
        fail(c.info.name + ": current radio export is unknown")
      }
      for (state, _, widget) in states {
        let expected = if export_name(state) == selected {
          state
        } else {
          name("Off")
        }
        guard get(self.document, widget, "AS") == Some(PdfNameObject(expected)) else {
          fail(c.info.name + ": radio value and appearance disagree")
        }
      }
    }
    Dropdown => {
      let options = dropdown_options(self.document, c)
      if value is Some(Selected(s)) {
        let indices : Array[@syntax.PdfObject] = []
        for i, pair in options {
          if pair.0 == s {
            indices.push(PdfInteger(i))
          }
        }
        guard indices.length() == 1 else {
          fail(c.info.name + ": current choice is unknown")
        }
        if get(self.document, c.object, "I") is Some(indices_value) {
          guard indices_value == PdfArray(indices) else {
            fail(c.info.name + ": choice value and index disagree")
          }
        }
      }
    }
    _ => ()
  }
  value
}

///|
/// Export supported, present values in field-tree order; refuse unsupported data.
/// Absent /V values are omitted. This is a value snapshot, not a PDF backup.
pub fn Form::values_json(self : Form) -> Json raise {
  let entries : Map[String, Json] = Map([])
  for c in self.controls {
    if self.checked_current(c) is Some(value) {
      entries[c.info.name] = match value {
        Text(s) => Json::string(s)
        Checked(b) => Json::boolean(b)
        Selected(s) => Json::object({ "select": Json::string(s) })
      }
    }
  }
  Json::object(entries)
}
