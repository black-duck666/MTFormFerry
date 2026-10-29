///|
async fn publish(bytes : Bytes, output : String) -> Unit {
  guard !@fs.exists(output) else { fail("output exists; choose a new path") }
  // The sibling is exclusive; rename never replaces an existing destination.
  let temporary = output + ".formferry-part"
  let file = @fs.create(temporary, allow_existing=false, sync=Full)
  errdefer (@fs.remove(temporary) catch { _ => () })
  {
    defer file.close()
    file.write(bytes)
  }
  @fs.rename(temporary, output, replace=false)
}
