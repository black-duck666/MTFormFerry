///|
async fn main {
  let args = @env.args()
  match args {
    [_, "values", path] => {
      guard @fs.file_size(path) <= 33554432L else { fail("PDF exceeds 32 MiB") }
      let form = @form.Form::open(@fs.read_file(path).binary())
      println(form.values_json().stringify(indent=2))
    }
    [_, "check", path] => {
      guard @fs.file_size(path) <= 33554432L else { fail("PDF exceeds 32 MiB") }
      let form = @form.Form::open(@fs.read_file(path).binary())
      let missing = form.missing_required()
      guard missing.is_empty() else {
        fail("missing required fields: " + missing.join(", "))
      }
      println("all Required fields satisfy the FormFerry completion policy")
    }
    [_, "batch" | "batch-complete", input, data, output] =>
      batch(input, data, output, complete=args[1] == "batch-complete")
    [_, "batch-csv" | "batch-csv-complete", input, data, output] =>
      batch(
        input,
        data,
        output,
        csv=true,
        complete=args[1] == "batch-csv-complete",
      )
    [_, "fields", path] => {
      guard @fs.file_size(path) <= 33554432L else { fail("PDF exceeds 32 MiB") }
      let form = @form.Form::open(@fs.read_file(path).binary())
      for field in form.fields() {
        println(
          "\{field.name}\t\{Repr(field.kind)}\tread_only=\{field.read_only}",
        )
        if field.kind is (Radio | Dropdown | Listbox) {
          println("  choices: " + form.choices(field.name).join(", "))
        }
      }
    }
    [_, "fill" | "complete", input, data, output] => {
      guard !@fs.exists(output) else {
        fail("output exists; choose a new path")
      }
      guard @fs.file_size(input) <= 33554432L && @fs.file_size(data) <= 1048576L else {
        fail("PDF or JSON exceeds input limit")
      }
      let form = @form.Form::open(@fs.read_file(input).binary())
      let values = @form.values_from_text(
        @utf8.decode(@fs.read_file(data).binary()),
      )
      let bytes = form.fill(values, complete=args[1] == "complete")
      let check = @form.Form::open(bytes)
      for key, value in values {
        guard check.value(key) == Some(value) else {
          fail("readback mismatch: " + key)
        }
      }
      // Sibling temporary file is exclusively created, then renamed without replacement.
      let temporary = output + ".formferry-part"
      let file = @fs.create(temporary, allow_existing=false, sync=Full)
      errdefer (@fs.remove(temporary) catch { _ => () })
      {
        defer file.close()
        file.write(bytes)
      }
      @fs.rename(temporary, output, replace=false)
      println("saved \{output}; verified \{values.length()} fields")
    }
    _ =>
      fail(
        "usage: formferry fields|values|check INPUT.pdf | formferry fill|complete INPUT.pdf VALUES.json NEW.pdf | formferry batch|batch-complete INPUT.pdf RECORDS.json NEW_DIRECTORY | formferry batch-csv|batch-csv-complete INPUT.pdf RECORDS.csv NEW_DIRECTORY",
      )
  }
}
