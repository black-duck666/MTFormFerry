///|
fn fitted_layout(
  value : String,
  width : Double,
  height : Double,
  base : Double,
  multiline : Bool,
  alignment : Int32,
  fit : Bool,
) -> (Double, String) raise {
  if !fit {
    return (
      base,
      text_operators(value, width, height, base, multiline, alignment~),
    )
  }
  let mut size = base
  // At most 25 candidates over 12..6pt; no unbounded search or truncation.
  for _ in 0..<25 {
    let operators = Some(
      text_operators(value, width, height, size, multiline, alignment~),
    ) catch {
      _ => None
    }
    if operators is Some(s) {
      return (size, s)
    }
    if size <= 6.0 {
      break
    }
    size = if size - 0.25 < 6.0 { 6.0 } else { size - 0.25 }
  }
  fail("text cannot fit without shrinking below 6pt")
}
