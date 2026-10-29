///|
fn comb_layout(
  value : String,
  cells : Int32,
  width : Double,
  base : Double,
  alignment : Int32,
  fit : Bool,
) -> (Double, String) raise {
  guard cells > 0 && cells <= 4096 && value.length() <= cells else {
    fail("Comb requires MaxLen in 1..4096 and a value within that limit")
  }
  let cell = (width - 4.0) / cells.to_double()
  let mut size = base
  for _ in 0..<25 {
    if size * 0.6 <= cell {
      break
    }
    guard fit && size > 6.0 else {
      fail("Comb cells are too narrow for the font size")
    }
    size = if size - 0.25 < 6.0 { 6.0 } else { size - 0.25 }
  }
  guard size * 0.6 <= cell else { fail("Comb cannot fit above the 6pt floor") }
  let first = match alignment {
    1 => (cells - value.length()) / 2
    2 => cells - value.length()
    _ => 0
  }
  let out = StringBuilder()
  for i, ch in value.iter().to_array() {
    let x = 2.0 + (first + i).to_double() * cell + (cell - size * 0.6) / 2.0
    out.write_string("1 0 0 1 \{x} 3 Tm (\{ascii_literal(ch.to_string())}) Tj ")
  }
  (size, out.to_string())
}
