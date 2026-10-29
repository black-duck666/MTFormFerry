///|
/// Named values: strings fill text, booleans checkboxes, {select: string} selects a choice.
pub fn values_from_json(input : Json) -> Map[String, Value] raise {
  guard input is Object(entries) else { fail("values must be a JSON object") }
  let values : Map[String, Value] = Map([])
  for key, value in entries {
    values[key] = match value {
      String(s) => Text(s)
      True => Checked(true)
      False => Checked(false)
      Object(m) => {
        guard m.length() == 1 && m.get("select") is Some(String(s)) else {
          fail(key + ": expected {select: string}")
        }
        Selected(s)
      }
      _ => fail(key + ": expected string, boolean or {select: string}")
    }
  }
  values
}

///|
/// Current values in the supported profile; absent values return None.
pub fn Form::value(self : Form, key : String) -> Value? raise {
  let fields = self.controls.filter(c => c.info.name == key)
  guard fields.length() == 1 else { fail("unknown field: " + key) }
  let control = fields[0]
  match (control.info.kind, get(self.document, control.object, "V")) {
    (Text, Some(s)) =>
      Some(Value::Text(read_text_value(s, (control.flags & 4096) != 0)))
    (Checkbox, Some(PdfNameObject(n))) => Some(Checked(n != name("Off")))
    (Radio, Some(PdfNameObject(n))) =>
      if n == name("Off") {
        None
      } else {
        Some(Selected(export_name(n)))
      }
    (Dropdown, Some(s)) => Some(Selected(text(s)))
    (_, None) => None
    _ => fail(key + ": unsupported current value")
  }
}

///|
/// Parse a flat JSON mapping and reject duplicate names, including escaped aliases.
pub fn values_from_text(source : String) -> Map[String, Value] raise {
  let parsed = @json.parse(source)
  let bytes = @utf8.encode(source)
  let scopes : Array[Map[String, Bool]] = []
  let mut i = 0
  while i < bytes.length() {
    if bytes[i] != b'"' {
      if bytes[i] == b'{' {
        scopes.push(Map([]))
      }
      if bytes[i] == b'}' {
        ignore(scopes.pop())
      }
      i += 1
      continue
    }
    let start = i
    i += 1
    while i < bytes.length() && bytes[i] != b'"' {
      if bytes[i] == b'\\' {
        i += 1
      }
      i += 1
    }
    i += 1
    let end = i
    while i < bytes.length() && [b' ', b'\n', b'\r', b'\t'].contains(bytes[i]) {
      i += 1
    }
    if i < bytes.length() && bytes[i] == b':' {
      guard @json.parse(@utf8.decode(bytes[start:end].to_owned()))
        is String(key) else {
        fail("invalid JSON key")
      }
      guard !scopes.is_empty() else { fail("JSON key outside object") }
      let seen = scopes[scopes.length() - 1]
      guard !seen.contains(key) else { fail("duplicate field: " + key) }
      seen[key] = true
    }
  }
  values_from_json(parsed)
}
