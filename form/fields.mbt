///|
pub(all) enum Kind {
  Text
  Checkbox
  Radio
  Dropdown
  Listbox
  Unsupported
} derive(Eq, Debug)

///|
pub(all) struct Field {
  name : String
  kind : Kind
  read_only : Bool
} derive(Eq, Debug)

///|
pub(all) enum Value {
  Text(String)
  Checked(Bool)
  Selected(String)
} derive(Eq, Debug)

///|
struct Control {
  info : Field
  number : Int32
  object : @syntax.PdfObject
  widgets : Array[(Int32, @syntax.PdfObject)]
  flags : Int32
}

///|
pub struct Form {
  priv original : Bytes
  priv document : @pdf.PdfDocument
  priv controls : Array[Control]
}

///|
fn name(s : String) -> @core.PdfName {
  @core.pdf_name_of_bytes(@utf8.encode("/" + s))
}

///|
fn get(
  doc : @pdf.PdfDocument,
  obj : @syntax.PdfObject,
  key : String,
) -> @syntax.PdfObject? {
  doc.lookup_direct(name(key), obj)
}

///|
fn text(obj : @syntax.PdfObject) -> String raise {
  guard obj is PdfString(b) else { fail("field name must be a PDF string") }
  guard b.iter().all(c => c.to_int() >= 32 && c.to_int() < 127) else {
    fail("field names currently require printable ASCII")
  }
  @utf8.decode(b)
}

///|
fn integer(obj : @syntax.PdfObject?) -> Int32 raise {
  match obj {
    None => 0
    Some(PdfInteger(n)) => n
    _ => fail("invalid field flags")
  }
}

///|
fn scan(
  doc : @pdf.PdfDocument,
  reference : @syntax.PdfObject,
  prefix : String,
  inherited_type : @syntax.PdfObject?,
  inherited_flags : Int32,
  seen : Map[Int32, Bool],
  out : Array[Control],
  depth : Int32,
) -> Unit raise {
  guard depth < 64 && seen.length() < 4096 else {
    fail("form tree exceeds limits")
  }
  guard reference is PdfIndirect(number) else {
    fail("field/widget must be an indirect object")
  }
  guard !seen.contains(number) else { fail("cyclic or shared field tree") }
  seen[number] = true
  let obj = doc.direct(reference)
  guard obj is PdfDictionary(_) else { fail("field is not a dictionary") }
  guard get(doc, obj, "AA") is None && get(doc, obj, "A") is None else {
    fail("field actions are unsupported")
  }
  let own_name = get(doc, obj, "T")
  let full = match own_name {
    Some(t) => {
      let part = text(t)
      guard !part.is_empty() && !part.contains(".") else {
        fail("invalid partial field name")
      }
      if prefix.is_empty() {
        part
      } else {
        prefix + "." + part
      }
    }
    None => prefix
  }
  let ft = match get(doc, obj, "FT") {
    Some(v) => Some(v)
    None => inherited_type
  }
  let flags = match get(doc, obj, "Ff") {
    None => inherited_flags
    some => integer(some)
  }
  guard ft != Some(PdfNameObject(name("Sig"))) else {
    fail("signature fields are unsupported")
  }
  let kids = match get(doc, obj, "Kids") {
    None => []
    Some(PdfArray(a)) => a
    _ => fail("invalid Kids array")
  }
  let child_fields = kids.filter(k => get(doc, doc.direct(k), "T") is Some(_))
  if !child_fields.is_empty() {
    guard child_fields.length() == kids.length() else {
      fail("mixed field and widget children")
    }
    for kid in kids {
      scan(doc, kid, full, ft, flags, seen, out, depth + 1)
    }
  } else {
    guard !full.is_empty() else { fail("terminal field has no name") }
    guard !out.any(c => c.info.name == full) else {
      fail("duplicate field name: " + full)
    }
    let widgets = if kids.is_empty() {
      [(number, obj)]
    } else {
      let result = []
      for kid in kids {
        guard seen.length() < 4096 else { fail("form tree exceeds limits") }
        guard kid is PdfIndirect(n) && !seen.contains(n) else {
          fail("invalid or shared widget")
        }
        seen[n] = true
        let widget = doc.direct(kid)
        guard get(doc, widget, "Subtype") == Some(PdfNameObject(name("Widget"))) else {
          fail("child is not a Widget")
        }
        guard get(doc, widget, "AA") is None && get(doc, widget, "A") is None else {
          fail("widget actions are unsupported")
        }
        result.push((n, widget))
      }
      result
    }
    let kind = if ft == Some(PdfNameObject(name("Tx"))) {
      Kind::Text
    } else if ft == Some(PdfNameObject(name("Btn"))) && (flags & 98304) == 0 {
      Checkbox
    } else if ft == Some(PdfNameObject(name("Btn"))) && (flags & 98304) == 32768 {
      Radio
    } else if ft == Some(PdfNameObject(name("Ch"))) && (flags & 131072) != 0 {
      Dropdown
    } else if ft == Some(PdfNameObject(name("Ch"))) {
      Listbox
    } else {
      Unsupported
    }
    out.push({
      info: { name: full, kind, read_only: (flags & 1) != 0, },
      number,
      object: obj,
      widgets,
      flags,
    })
  }
}

///|
/// Open an unencrypted AcroForm. Unsupported field kinds are retained but cannot be filled.
pub fn Form::open(bytes : Bytes) -> Form raise {
  guard bytes.length() <= 32 * 1024 * 1024 else {
    fail("PDF exceeds 32 MiB input limit")
  }
  let doc = @pdf.pdf_read_document_from_bytes(bytes)
  guard get(doc, doc.trailer_dict(), "Encrypt") is None else {
    fail("encrypted PDFs are unsupported")
  }
  let catalog = doc.catalog()
  guard get(doc, catalog, "Perms") is None else {
    fail("certified PDFs are unsupported")
  }
  guard get(doc, catalog, "OpenAction") is None &&
    get(doc, catalog, "AA") is None else {
    fail("document actions are unsupported")
  }
  guard get(doc, catalog, "AcroForm") is Some(acro) else {
    fail("PDF has no AcroForm")
  }
  guard get(doc, acro, "XFA") is None && get(doc, acro, "CO") is None else {
    fail("XFA and calculated forms are unsupported")
  }
  guard get(doc, acro, "Fields") is Some(PdfArray(fields)) else {
    fail("AcroForm has no Fields array")
  }
  let controls = []
  let seen = Map([])
  for field in fields {
    scan(doc, field, "", None, 0, seen, controls, 0)
  }
  { original: bytes, document: doc, controls, }
}

///|
pub fn Form::fields(self : Form) -> Array[Field] {
  self.controls.map(c => c.info)
}

///|
pub extend Kind with Eq::{equal, not_equal}

///|
pub extend Kind with Debug::{to_repr}

///|
pub extend Field with Eq::{equal, not_equal}

///|
pub extend Field with Debug::{to_repr}

///|
pub extend Value with Eq::{equal, not_equal}

///|
pub extend Value with Debug::{to_repr}
