///|
fn reset_value(doc : @pdf.PdfDocument, c : Control) -> Value? raise {
  let dv = inherited(doc, c.object, "DV")
  match (c.info.kind, dv) {
    (Text, None) => Some(Value::Text(""))
    (Text, Some(s)) =>
      Some(Value::Text(read_text_value(s, (c.flags & 4096) != 0)))
    (Checkbox, None) => Some(Checked(false))
    (Checkbox, Some(PdfNameObject(n))) => {
      if n != name("Off") {
        for (_, widget) in c.widgets {
          guard get(doc, widget, "AP") is Some(ap) &&
            get(doc, ap, "N") is Some(PdfDictionary(entries)) &&
            entries.any(p => p.0 == n) else {
            fail(c.info.name + ": default checkbox export is unknown")
          }
        }
      }
      Some(Checked(n != name("Off")))
    }
    (Radio, None) => None
    (Radio, Some(PdfNameObject(n))) =>
      if n == name("Off") {
        None
      } else {
        Some(Selected(export_name(n)))
      }
    (Dropdown | Listbox, None) => None
    (Listbox, Some(s)) if (c.flags & 2097152) != 0 => {
      let items = match s {
        PdfArray(a) => a
        _ => [s]
      }
      Some(Selections(items.map(item => text(doc.direct(item)))))
    }
    (Dropdown | Listbox, Some(s)) => Some(Selected(text(s)))
    _ => fail(c.info.name + ": unsupported default value")
  }
}

///|
fn clear_control(doc : @pdf.PdfDocument, c : Control) -> Unit raise {
  if c.info.kind == Radio {
    let states = radio_states(doc, c)
    doc.add_object_given_number(
      c.number,
      c.object.add_dict_entry(name("V"), PdfNameObject(name("Off"))),
    )
    for (_, id, widget) in states {
      let updated = widget.add_dict_entry(
        name("AS"),
        PdfNameObject(name("Off")),
      )
      let updated = if id == c.number {
        updated.add_dict_entry(name("V"), PdfNameObject(name("Off")))
      } else {
        updated
      }
      doc.add_object_given_number(id, updated)
    }
  } else {
    let options = dropdown_options(doc, c)
    reject_inherited_clear(doc, c)
    fill_text(
      doc,
      c,
      "",
      choice=true,
      list_options=if c.info.kind == Listbox {
        options.map(p => p.1)
      } else {
        []
      },
    )
    let field = doc
      .direct(PdfIndirect(c.number))
      .remove_dict_entry(name("V"))
      .remove_dict_entry(name("I"))
    doc.add_object_given_number(
      c.number,
      if c.info.kind == Listbox {
        field.add_dict_entry(name("TI"), PdfInteger(0))
      } else {
        field
      },
    )
  }
}

///|
/// Reset named writable controls to inherited PDF defaults, or documented empty states.
/// The operation is atomic and preserves all unselected fields and original bytes.
pub fn Form::reset(
  self : Form,
  fields : Array[String],
  complete~ : Bool = false,
  fit_text~ : Bool = false,
) -> Bytes raise {
  guard fields.length() > 0 && fields.length() <= 4096 else {
    fail("reset needs 1 to 4096 field names")
  }
  let selected : Map[String, Bool] = Map([])
  for key in fields {
    guard !selected.contains(key) && self.controls.any(c => c.info.name == key) else {
      fail("reset duplicate or unknown field: " + key)
    }
    selected[key] = true
  }
  let doc = @pdf.pdf_read_document_from_bytes(self.original)
  let expected : Map[String, Value?] = Map([])
  for c in self.controls {
    if !selected.contains(c.info.name) {
      continue
    }
    guard !c.info.read_only else { fail(c.info.name + ": field is read-only") }
    let value = reset_value(doc, c) catch {
      e => fail(c.info.name + ": invalid default: " + e.to_string())
    }
    match value {
      Some(v) => write_value(doc, c, v, fit_text)
      None => clear_control(doc, c)
    }
    expected[c.info.name] = value
  }
  let bytes = @pdf.pdf_write_document_incremental_update(self.original, doc)
  let check = Form::open(bytes)
  for c in check.controls {
    if !selected.contains(c.info.name) {
      continue
    }
    let actual = check.checked_current(c)
    let expected = expected[c.info.name]
    let same = match expected {
      Some(v) => matches_value(v, actual)
      None => actual is None
    }
    guard same else { fail(c.info.name + ": reset readback mismatch") }
  }
  if complete {
    let missing = check.missing_required()
    guard missing.is_empty() else {
      fail("missing required fields: " + missing.join(", "))
    }
  }
  bytes
}
