///|
async fn main {
  let raw = @env.args()
  let fit_text = raw.get(raw.length() - 1) == Some("--fit-text")
  let args = if fit_text { raw[:raw.length() - 1].to_owned() } else { raw }
  guard !fit_text ||
    args.get(1)
    is Some(
      "fill"
      | "complete"
      | "batch"
      | "batch-complete"
      | "batch-csv"
      | "batch-csv-complete"
      | "reset"
    ) else {
    fail("--fit-text is only supported for fill, batch and reset commands")
  }
  match args {
    [_, "reset", input, data, output] => {
      guard !@fs.exists(output) else {
        fail("output exists; choose a new path")
      }
      guard @fs.file_size(input) <= 33554432L && @fs.file_size(data) <= 1048576L else {
        fail("PDF or JSON exceeds input limit")
      }
      guard @json.parse(@utf8.decode(@fs.read_file(data).binary()))
        is Array(names) else {
        fail("reset names must be a JSON string array")
      }
      let fields = []
      for item in names {
        guard item is String(s) else { fail("reset name must be a string") }
        fields.push(s)
      }
      let form = @form.Form::open(@fs.read_file(input).binary())
      let bytes = form.reset(fields, fit_text~)
      publish(bytes, output)
      println("saved \{output}; reset and verified \{fields.length()} fields")
    }
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
      batch(
        input,
        data,
        output,
        complete=args[1] == "batch-complete",
        fit_text~,
      )
    [_, "batch-csv" | "batch-csv-complete", input, data, output] =>
      batch(
        input,
        data,
        output,
        csv=true,
        complete=args[1] == "batch-csv-complete",
        fit_text~,
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
      let bytes = form.fill(values, complete=args[1] == "complete", fit_text~)
      let check = @form.Form::open(bytes)
      for key, value in values {
        let actual = check.value(key)
        guard actual == Some(value) ||
          (value is Selections(s) && s.is_empty() && actual is None) else {
          fail("readback mismatch: " + key)
        }
      }
      publish(bytes, output)
      println("saved \{output}; verified \{values.length()} fields")
    }
    _ =>
      fail(
        "usage: formferry fields|values|check INPUT.pdf | formferry fill|complete INPUT.pdf VALUES.json NEW.pdf [--fit-text] | formferry reset INPUT.pdf NAMES.json NEW.pdf [--fit-text] | formferry batch|batch-complete INPUT.pdf RECORDS.json NEW_DIRECTORY [--fit-text] | formferry batch-csv|batch-csv-complete INPUT.pdf RECORDS.csv NEW_DIRECTORY [--fit-text]",
      )
  }
}
