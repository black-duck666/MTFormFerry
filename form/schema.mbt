///|
/// Export versioned template metadata for building review/input forms; not JSON Schema.
pub fn Form::schema_json(self : Form) -> Json raise {
  let fields = []
  for c in self.controls {
    let kind = match c.info.kind {
      Text => "text"
      Checkbox => "checkbox"
      Radio => "radio"
      Dropdown => "dropdown"
      Listbox => "listbox"
      Unsupported => "unsupported"
    }
    let metadata : Map[String, Json] = {
      "name": Json::string(c.info.name),
      "kind": Json::string(kind),
      "read_only": Json::boolean(c.info.read_only),
      "required": Json::boolean((c.flags & 2) != 0),
    }
    let supported = match c.info.kind {
      Text =>
        c.flags >= 0 &&
        ((c.flags & 4103) == c.flags || (c.flags & 16777223) == c.flags)
      Radio => c.flags >= 32768 && (c.flags & 49159) == c.flags
      Dropdown => c.flags >= 131072 && (c.flags & 131079) == c.flags
      Listbox => c.flags >= 0 && (c.flags & 2097159) == c.flags
      Checkbox => true
      Unsupported => false
    }
    metadata["supported"] = Json::boolean(supported)
    metadata["writable"] = Json::boolean(supported && !c.info.read_only)
    if c.info.kind == Text {
      let limit = match inherited(self.document, c.object, "MaxLen") {
        None => Json::null()
        Some(PdfInteger(n)) if n >= 0 => Json::number(n.to_double())
        _ => fail(c.info.name + ": invalid MaxLen")
      }
      if (c.flags & 16777216) != 0 {
        guard limit is Number(n, ..) && n >= 1.0 && n <= 4096.0 else {
          fail(c.info.name + ": invalid Comb MaxLen")
        }
      }
      metadata["max_length"] = limit
      metadata["text_limit"] = Json::number(4096.0)
      metadata["multiline"] = Json::boolean((c.flags & 4096) != 0)
      metadata["comb"] = Json::boolean((c.flags & 16777216) != 0)
      metadata["alignment"] = Json::string(
        match text_alignment(self.document, c) {
          1 => "center"
          2 => "right"
          _ => "left"
        },
      )
    }
    if c.info.kind is (Radio | Dropdown | Listbox) && supported {
      let options = if c.info.kind == Radio {
        self
        .choices(c.info.name)
        .map(s => {
          Json::object({ "export": Json::string(s), "label": Json::null() })
        })
      } else {
        dropdown_options(self.document, c).map(p => {
          Json::object({
            "export": Json::string(p.0),
            "label": Json::string(p.1),
          })
        })
      }
      metadata["options"] = Json::array(options)
      metadata["multiple"] = Json::boolean(
        c.info.kind == Listbox && (c.flags & 2097152) != 0,
      )
    }
    fields.push(Json::object(metadata))
  }
  Json::object({ "version": Json::number(1.0), "fields": Json::array(fields) })
}
