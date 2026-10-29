///|
fn fdf_header(bytes : Bytes, header : Bytes) -> Bytes {
  let result = header.iter().to_array()
  for b in bytes[8:] {
    result.push(b)
  }
  Bytes::from_array(result)
}

///|
fn fdf_dictionary(
  doc : @pdf.PdfDocument,
  object : @syntax.PdfObject,
  allowed : Array[String],
) -> Unit raise {
  guard doc.direct(object) is PdfDictionary(entries) else {
    fail("FDF expected a dictionary")
  }
  for (key, _) in entries {
    guard allowed.any(s => name(s) == key) &&
      entries.filter(p => p.0 == key).length() == 1 else {
      fail("FDF contains duplicate or unsupported dictionary entries")
    }
  }
}

///|
fn fdf_tree(
  entries : Array[(Array[String], @syntax.PdfObject)],
  depth : Int32,
) -> Array[@syntax.PdfObject] raise {
  guard depth < 64 else { fail("FDF tree exceeds depth limit") }
  let groups : Map[String, Array[(Array[String], @syntax.PdfObject)]] = Map([])
  for entry in entries {
    let key = entry.0[0]
    if groups.get(key) is Some(group) {
      group.push(entry)
    } else {
      groups[key] = [entry]
    }
  }
  let result = []
  for key, group in groups {
    let direct = group.filter(e => e.0.length() == 1)
    let field = @syntax.PdfDictionary([
      (name("T"), PdfString(@utf8.encode(key))),
    ])
    if !direct.is_empty() {
      guard group.length() == 1 else {
        fail("FDF ambiguous leaf/group name: " + key)
      }
      result.push(field.add_dict_entry(name("V"), direct[0].1))
    } else {
      result.push(
        field.add_dict_entry(
          name("Kids"),
          PdfArray(
            fdf_tree(group.map(e => (e.0[1:].to_owned(), e.1)), depth + 1),
          ),
        ),
      )
    }
  }
  result
}

///|
/// Export present supported values as a deterministic, values-only FDF 1.2 file.
pub fn Form::values_fdf(self : Form) -> Bytes raise {
  let entries = []
  for c in self.controls {
    if self.checked_current(c) is Some(v) {
      let value : @syntax.PdfObject = match v {
        Text(s) | Selected(s) =>
          if c.info.kind == Radio {
            PdfNameObject(name(s))
          } else {
            PdfString(@utf8.encode(s))
          }
        Checked(_) => inherited(self.document, c.object, "V").unwrap()
        Selections(s) =>
          PdfArray(s.map(v => @syntax.PdfObject::PdfString(@utf8.encode(v))))
      }
      entries.push(
        (c.info.name.split(".").map(v => v.to_owned()).to_array(), value),
      )
    }
  }
  let doc = @pdf.pdf_document_empty()
  doc.set_version(1, 2)
  let root = doc.add_object(
    PdfDictionary([
      (
        name("FDF"),
        PdfDictionary([(name("Fields"), PdfArray(fdf_tree(entries, 0)))]),
      ),
    ]),
  )
  doc.set_root(root)
  doc.set_trailer_dict(PdfDictionary([(name("Root"), PdfIndirect(root))]))
  let bytes = fdf_header(@pdf.pdf_write_document(doc), b"%FDF-1.2")
  guard bytes.length() <= 1048576 else { fail("FDF exceeds 1 MiB") }
  bytes
}

///|
fn Form::fdf_fields(
  self : Form,
  doc : @pdf.PdfDocument,
  fields : Array[@syntax.PdfObject],
  prefix : String,
  values : Map[String, Value],
  seen : Map[Int32, Bool],
  count : Ref[Int32],
  depth : Int32,
) -> Unit raise {
  guard depth < 64 else { fail("FDF tree exceeds depth limit") }
  for field in fields {
    count.val += 1
    guard count.val <= 4096 else { fail("FDF exceeds 4096 fields") }
    if field is PdfIndirect(id) {
      guard !seen.contains(id) else { fail("FDF cyclic or shared field") }
      seen[id] = true
    }
    fdf_dictionary(doc, field, ["T", "V", "Kids"])
    guard get(doc, field, "T") is Some(t) else { fail("FDF field has no name") }
    let part = text(t)
    guard !part.is_empty() else { fail("FDF empty field name") }
    let key = if prefix.is_empty() { part } else { prefix + "." + part }
    match get(doc, field, "Kids") {
      Some(PdfArray(children)) => {
        guard !children.is_empty() && get(doc, field, "V") is None else {
          fail("FDF mixed or empty group")
        }
        self.fdf_fields(doc, children, key, values, seen, count, depth + 1)
      }
      None => {
        guard !values.contains(key) else { fail("FDF duplicate field: " + key) }
        let matches = self.controls.filter(c => c.info.name == key)
        guard matches.length() == 1 else { fail("FDF unknown field: " + key) }
        let c = matches[0]
        guard !c.info.read_only else { fail(key + ": FDF target is read-only") }
        guard get(doc, field, "V") is Some(v) else {
          fail(key + ": FDF leaf has no value")
        }
        values[key] = match (c.info.kind, v) {
          (Text, s) => Value::Text(read_text_value(s, (c.flags & 4096) != 0))
          (Checkbox, PdfNameObject(n)) => {
            if n != name("Off") {
              for (_, w) in c.widgets {
                guard get(self.document, w, "AP") is Some(ap) &&
                  get(self.document, ap, "N") is Some(PdfDictionary(states)) &&
                  states.any(p => p.0 == n) else {
                  fail(key + ": unknown FDF checkbox export")
                }
              }
            }
            Checked(n != name("Off"))
          }
          (Radio, PdfNameObject(n)) => {
            guard n != name("Off") else {
              fail(key + ": FDF Off radio value requires reset")
            }
            Selected(export_name(n))
          }
          (Listbox, s) if (c.flags & 2097152) != 0 => {
            let items = match s {
              PdfArray(a) => a
              _ => [s]
            }
            Selections(items.map(s => text(doc.direct(s))))
          }
          (Dropdown | Listbox, s) => Selected(text(s))
          _ => fail(key + ": unsupported FDF field value")
        }
      }
      _ => fail("FDF invalid Kids")
    }
  }
}

///|
/// Import the values-only FDF 1.2 profile against this template. Fill validates layout.
pub fn Form::values_from_fdf(
  self : Form,
  bytes : Bytes,
) -> Map[String, Value] raise {
  guard bytes.length() >= 9 &&
    bytes.length() <= 1048576 &&
    bytes[:8] == b"%FDF-1.2" &&
    (bytes[8] == b'\n' || bytes[8] == b'\r') else {
    fail("expected FDF 1.2 within 1 MiB")
  }
  let doc = @pdf.pdf_read_classic_document_from_bytes(
    fdf_header(bytes, b"%PDF-1.2"),
  )
  fdf_dictionary(doc, doc.trailer_dict(), ["Root", "Size"])
  let root = doc.catalog()
  fdf_dictionary(doc, root, ["FDF"])
  guard get(doc, root, "FDF") is Some(fdf) else {
    fail("FDF catalog has no FDF dictionary")
  }
  fdf_dictionary(doc, fdf, ["Fields"])
  guard get(doc, fdf, "Fields") is Some(PdfArray(fields)) else {
    fail("FDF missing Fields array")
  }
  let values = Map([])
  self.fdf_fields(doc, fields, "", values, Map([]), Ref::{ val: 0, }, 0)
  values
}
