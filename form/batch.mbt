///| Produce independent PDFs in input order; reject the whole batch on any error.

///|
/// Limits: 1..32 records and 64 MiB combined encoded output.
pub fn Form::fill_batch(
  self : Form,
  records : Array[Map[String, Value]],
) -> Array[Bytes] raise {
  guard records.length() >= 1 && records.length() <= 32 else {
    fail("batch needs 1 to 32 records")
  }
  let result = []
  let mut total = 0L
  for i, values in records {
    let bytes = self.fill(values) catch {
      e => fail("record \{i+1}: " + e.to_string())
    }
    total += bytes.length().to_int64()
    guard total <= 67108864L else { fail("batch output exceeds 64 MiB") }
    let check = Form::open(bytes)
    for key, value in values {
      guard check.value(key) == Some(value) else {
        fail("record \{i+1}: readback mismatch for " + key)
      }
    }
    result.push(bytes)
  }
  result
}
