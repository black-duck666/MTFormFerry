# Batch fill

`records_from_text(source)` reads a JSON array of named-value objects. `form.fill_batch(records)` produces independent PDFs in input order, reopening each result to verify assigned values. Any malformed record, unsupported field/value or layout failure aborts the whole operation and identifies the record. Limits are 1..32 records, the existing per-field limits and 64 MiB of combined encoded output.

```
moon run samples/make_template.mbtx
moon run samples/make_choices.mbtx
moon run bin/formferry --target wasm -- batch samples/choices.pdf samples/batch.json _build/registrations
```

The directory must not already exist. Outputs are `0001.pdf`, `0002.pdf`, etc. All records are prepared before disk output. The CLI exclusively creates a sibling `.formferry-part` directory, synchronizes and closes each file, then renames the directory without replacement. Errors clean up only the files created by this invocation. Existing destinations/staging directories are not removed. This provides publication isolation, not a claimed guarantee against power loss.

Use this for registration packets, maintenance records or repeated application forms. It is not CSV guessing, mail delivery, arbitrary template generation or a PDF merge operation. Run `moon run samples/verify.mbtx wasm` for an end-to-end batch success/overwrite/rejected-record check; native CI runs the same workflow.
