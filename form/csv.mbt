///|
// Bounded CSV input profile for the form workflow, not a general CSV API.
fn csv_rows(source : String) -> Array[Array[String]] raise {
  let bytes = @utf8.encode(source)
  guard bytes.length() > 0 && bytes.length() <= 1048576 else {
    fail("CSV needs 1 byte to 1 MiB")
  }
  guard bytes
    .iter()
    .all(b => (b >= b' ' && b <= b'~') || b == b'\r' || b == b'\n') else {
    fail("CSV requires ASCII, with CR/LF record or quoted cell breaks")
  }
  let rows = []
  let mut row : Array[String] = []
  let mut cell = StringBuilder()
  // 0: start; 1: unquoted; 2: quoted; 3: closed quote.
  let mut state = 0
  let mut i = 0
  while i < bytes.length() {
    let b = bytes[i]
    if state == 2 {
      if b == b'"' {
        if i + 1 < bytes.length() && bytes[i + 1] == b'"' {
          cell.write_char('"')
          i += 2
        } else {
          state = 3
          i += 1
        }
      } else {
        cell.write_char(b.to_int().unsafe_to_char())
        i += 1
      }
    } else if b == b',' || b == b'\r' || b == b'\n' {
      let value = cell.to_string()
      guard value.length() <= 4096 && row.length() < 4096 else {
        fail("CSV cell or column limit exceeded")
      }
      row.push(value)
      cell = StringBuilder()
      state = 0
      i += 1
      if b != b',' {
        if b == b'\r' {
          guard i < bytes.length() && bytes[i] == b'\n' else {
            fail("CSV bare CR record separator")
          }
          i += 1
        }
        rows.push(row)
        guard rows.length() <= 33 else { fail("CSV exceeds 32 data records") }
        row = []
      }
    } else if b == b'"' {
      guard state == 0 else { fail("CSV quote inside an unquoted cell") }
      state = 2
      i += 1
    } else {
      guard state != 3 else { fail("CSV characters after a closing quote") }
      cell.write_char(b.to_int().unsafe_to_char())
      state = 1
      i += 1
    }
  }
  guard state != 2 else { fail("CSV unterminated quoted cell") }
  if state != 0 || !row.is_empty() || bytes[bytes.length() - 1] == b',' {
    let value = cell.to_string()
    guard value.length() <= 4096 && row.length() < 4096 else {
      fail("CSV cell or column limit exceeded")
    }
    row.push(value)
    rows.push(row)
  }
  guard rows.length() >= 2 && rows.length() <= 33 else {
    fail("CSV needs a header and 1 to 32 data records")
  }
  rows
}

///|
/// Convert a headered ASCII CSV into typed form records without trimming or inference.
/// Text cells are literal; checkboxes require true/false; choices use actual exports.
pub fn Form::records_from_csv(
  self : Form,
  source : String,
) -> Array[Map[String, Value]] raise {
  let rows = csv_rows(source)
  let headers = rows[0]
  let seen : Map[String, Bool] = Map([])
  let controls = []
  for key in headers {
    guard !key.is_empty() && !seen.contains(key) else {
      fail("CSV empty or duplicate header: " + key)
    }
    seen[key] = true
    let matches = self.controls.filter(c => c.info.name == key)
    guard matches.length() == 1 else { fail("CSV unknown field: " + key) }
    let c = matches[0]
    guard !c.info.read_only && c.info.kind != Unsupported else {
      fail("CSV field cannot be written: " + key)
    }
    controls.push(c)
  }
  let result = []
  for index in 1..<rows.length() {
    let cells = rows[index]
    guard cells.length() == headers.length() else {
      fail("CSV record \{index}: column count differs from header")
    }
    let record : Map[String, Value] = Map([])
    for col, c in controls {
      let s = cells[col]
      record[c.info.name] = match c.info.kind {
        Text => Value::Text(s)
        Checkbox => {
          guard s == "true" || s == "false" else {
            fail(
              "CSV record \{index}, \{c.info.name}: checkbox needs true or false",
            )
          }
          Checked(s == "true")
        }
        Radio | Dropdown | Listbox => {
          guard self.choices(c.info.name).contains(s) else {
            fail("CSV record \{index}, \{c.info.name}: unknown choice export")
          }
          Selected(s)
        }
        Unsupported => fail("CSV unsupported field: " + c.info.name)
      }
    }
    result.push(record)
  }
  result
}
