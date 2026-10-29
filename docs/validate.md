# Review all field errors before saving

`form.validate(values, complete=true)` returns `Array[ValidationIssue]` with field names and actionable messages, instead of stopping at the first incorrect value. It uses the actual field writers for flags, choices, MaxLen, appearances and layout. Required checks evaluate supplied candidate values and untouched existing values. Failed scratch writes are discarded before validating another field; neither the original bytes nor reusable Form change.

Known fields appear in template order, followed by unknown names in lexical order, independent of map insertion order. A bad update produces one issue for that field; it is not also reported as missing. `complete=false` permits drafts, and `fit_text=true` uses the existing fitting policy. Opening/parsing errors still raise; this API checks semantic/layout eligibility, not eventual serialization, filesystem errors or external acceptance.

Run `moon run bin/formferry --target wasm -- validate-complete samples/project.pdf samples/project.json`. JSON issues go to stdout, with nonzero exit when any issue exists; no PDF is written. Use `validate` for drafts. The trailing `--fit-text` is supported. This is intended for application review screens and batch input correction before calling fill.
