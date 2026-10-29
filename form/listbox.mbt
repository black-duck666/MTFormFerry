///|
fn list_drawing(
  labels : Array[String],
  selected : Int32,
  width : Double,
  height : Double,
  size : Double,
) -> String raise {
  let leading = size * 1.2
  guard !labels.is_empty() && selected >= 0 && selected < labels.length() else {
    fail("invalid list selection")
  }
  guard labels.length().to_double() * leading <= height - 4.0 else {
    fail("list options would overflow vertically; scrolling is unsupported")
  }
  let out = StringBuilder()
  out.write_string("1 g 0 0 \{width} \{height} re f ")
  for i, label in labels {
    guard label.iter().all(ch => ch >= ' ' && ch <= '~') &&
      label.length().to_double() * size * 0.6 <= width - 4.0 else {
      fail("list label requires ASCII and must fit the widget width")
    }
    let baseline = height - 2.0 - size - i.to_double() * leading
    if i == selected {
      let bottom = baseline - size * 0.2
      let available = width - 4.0
      out.write_string("0.85 g 2 \{bottom} \{available} \{leading} re f ")
    }
    out.write_string(
      "BT /FormFerryCourier \{size} Tf 0 g 1 0 0 1 2 \{baseline} Tm (\{ascii_literal(label)}) Tj ET ",
    )
  }
  out.to_string()
}
