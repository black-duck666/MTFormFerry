///|
fn text_operators(
  value : String,
  width : Double,
  height : Double,
  size : Double,
  multiline : Bool,
  alignment~ : Int32 = 0,
) -> String raise {
  guard alignment >= 0 && alignment <= 2 else { fail("invalid text alignment") }
  if !multiline {
    guard value.length().to_double() * size * 0.6 <= width - 4.0 else {
      fail("text would overflow at the plain 12pt style")
    }
    let x = aligned_x(value.length(), width, size, alignment)
    return "\{x} 3 Td (\{ascii_literal(value)}) Tj"
  }
  let columns = ((width - 4.0) / (size * 0.6)).to_int()
  guard columns > 0 else { fail("text box too narrow") }
  let lines = []
  let mut line = ""
  for c in value {
    if c == '\n' {
      lines.push(line)
      line = ""
    } else {
      if line.length() == columns {
        lines.push(line)
        line = ""
      }
      line += c.to_string()
    }
  }
  lines.push(line)
  let leading = size * 1.2
  guard lines.length().to_double() * leading <= height - 4.0 else {
    fail("multiline text would overflow vertically")
  }
  let out = StringBuilder()
  for i, s in lines {
    let baseline = height - 2.0 - size - i.to_double() * leading
    let x = aligned_x(s.length(), width, size, alignment)
    out.write_string("1 0 0 1 \{x} \{baseline} Tm (\{ascii_literal(s)}) Tj ")
  }
  out.to_string()
}

///|
fn aligned_x(
  length : Int32,
  width : Double,
  size : Double,
  alignment : Int32,
) -> Double {
  let occupied = length.to_double() * size * 0.6
  match alignment {
    1 => (width - occupied) / 2.0
    2 => width - 2.0 - occupied
    _ => 2.0
  }
}

///|
fn read_text_value(obj : @syntax.PdfObject, multiline : Bool) -> String raise {
  guard obj is PdfString(bytes) else { fail("text value must be a string") }
  guard bytes
    .iter()
    .all(c => {
      (c.to_int() >= 32 && c.to_int() <= 126) || (multiline && c == b'\n')
    }) else {
    fail("unsupported text encoding")
  }
  @utf8.decode(bytes)
}
