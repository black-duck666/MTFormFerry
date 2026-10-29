///|
/// Set ReadOnly on selected terminal fields, preserving values, appearances and other flags.
/// This viewer hint is not encryption, signing, flattening or tamper protection.
pub fn Form::lock(
  self : Form,
  fields : Array[String],
  complete~ : Bool = false,
) -> Bytes raise {
  guard fields.length() > 0 && fields.length() <= 4096 else {
    fail("lock needs 1 to 4096 field names")
  }
  let selected : Map[String, Bool] = Map([])
  for key in fields {
    guard !selected.contains(key) && self.controls.any(c => c.info.name == key) else {
      fail("lock duplicate or unknown field: " + key)
    }
    selected[key] = true
  }
  if complete {
    let missing = self.missing_required()
    guard missing.is_empty() else {
      fail("missing required fields: " + missing.join(", "))
    }
  }
  let doc = @pdf.pdf_read_document_from_bytes(self.original)
  let mut changed = false
  for c in self.controls {
    if !selected.contains(c.info.name) {
      continue
    }
    guard c.flags >= 0 else {
      fail(c.info.name + ": invalid negative field flags")
    }
    if !c.info.read_only {
      guard c.object is PdfDictionary(entries) else {
        fail("lock expected field dictionary")
      }
      guard entries.filter(p => p.0 == name("Ff")).length() <= 1 else {
        fail(c.info.name + ": duplicate flags")
      }
      let updated = entries.map(p => {
        if p.0 == name("Ff") {
          (p.0, @syntax.PdfObject::PdfInteger(c.flags | 1))
        } else {
          p
        }
      })
      if !entries.any(p => p.0 == name("Ff")) {
        updated.push((name("Ff"), PdfInteger(c.flags | 1)))
      }
      doc.add_object_given_number(c.number, PdfDictionary(updated))
      changed = true
    }
  }
  if !changed {
    return self.original
  }
  let bytes = @pdf.pdf_write_document_incremental_update(self.original, doc)
  let check = Form::open(bytes)
  guard check.controls.length() == self.controls.length() else {
    fail("lock changed field count")
  }
  for i, before in self.controls {
    let after = check.controls[i]
    guard before.info.name == after.info.name else {
      fail("lock changed field order")
    }
    if selected.contains(before.info.name) {
      guard after.info.read_only &&
        @pdf.pdf_write_object(before.object.remove_dict_entry(name("Ff"))) ==
        @pdf.pdf_write_object(after.object.remove_dict_entry(name("Ff"))) else {
        fail(before.info.name + ": lock verification failed")
      }
    } else {
      guard before.object == after.object else {
        fail(before.info.name + ": unselected field changed")
      }
    }
  }
  bytes
}
