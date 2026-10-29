///|
async fn batch(input : String, data : String, output : String) -> Unit {
  guard !@fs.exists(output) else {
    fail("batch output exists; choose a new directory")
  }
  guard @fs.file_size(input) <= 33554432L && @fs.file_size(data) <= 1048576L else {
    fail("PDF or JSON exceeds input limit")
  }
  let form = @form.Form::open(@fs.read_file(input).binary())
  let records = @form.records_from_text(
    @utf8.decode(@fs.read_file(data).binary()),
  )
  let documents = form.fill_batch(records)
  let staging = output + ".formferry-part"
  @fs.mkdir(staging, permission=0o700, allow_exist=false)
  let written : Array[String] = []
  errdefer {
    for file in written {
      @fs.remove(file) catch {
        _ => ()
      }
    }
    @fs.rmdir(staging) catch {
      _ => ()
    }
  }
  for i, bytes in documents {
    let digits = (i + 1).to_string()
    let path = staging + "/" + "0".repeat(4 - digits.length()) + digits + ".pdf"
    let file = @fs.create(path, allow_existing=false, sync=Full)
    written.push(path)
    defer file.close()
    file.write(bytes)
  }
  @fs.rename(staging, output, replace=false)
  println("saved \{documents.length()} verified PDFs to \{output}")
}
