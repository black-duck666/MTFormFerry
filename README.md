# FormFerry · 笺舟

[Comb fields](docs/comb.md) fill fixed character cells for identifiers and reference codes, honoring MaxLen, alignment and optional fitting.

[Template alignment](docs/alignment.md) preserves left, centered and right-aligned text, including inherited settings and each multiline row.

[Optional text fitting](docs/fit.md) shrinks overflowing ASCII text down to a 6pt floor while retaining the exact value; the default still rejects overflow.

[Reset to defaults](docs/reset.md) restores selected fields to PDF defaults or explicit empty states, regenerates appearances and verifies readback before publication.

[Value snapshots](docs/values.md) export existing supported values as deterministic JSON for review and reuse; inconsistent button appearances and unsupported controls are refused.

[Completion checks](docs/completion.md) distinguish drafts from completed applications: list missing Required fields, or fill with `complete=true` before publishing an individual PDF or a batch.

[CSV batches](docs/csv.md) turn headered spreadsheet exports into typed records and verified PDFs, with explicit checkbox/choice conversion and whole-batch failure.

Radio groups are supported through `Selected(export_name)` or JSON `{"answer":{"select":"No"}}`. Discover actual exports with `form.choices("answer")`; see [radio groups](docs/radio.md). Existing on/off appearances are reused and all widgets are synchronized.

[Dropdowns](docs/dropdown.md) and [single-selection lists](docs/listbox.md) use `Selected(export)`. [Multi-selection lists](docs/multiselect.md) use `Selections(exports)` and highlight each selected row. Stored exports and visible labels are handled separately; editable controls and list overflow are rejected.

[Multiline text](docs/multiline.md) accepts explicit LF newlines on Multiline fields, preserves the stored value, measures hard wrapping and refuses vertical overflow. Single-line behavior remains unchanged.

[Batch filling](docs/batch.md) accepts 1..32 JSON records, verifies every output and publishes a new directory only after the whole batch succeeds. No failed records are skipped.

Fill existing PDF AcroForm controls from MoonBit. Checkboxes and radio groups select existing appearance states; plain ASCII text and dropdown labels get explicit Courier appearance streams. Saving appends an incremental update and retains the original bytes. Other controls remain untouched and cannot be filled.

Import `black-duck666/formferry/form`. Open bytes with `Form::open`, inspect `fields()`, then call `fill({ "approved": Checked(true) })`. Each call returns new bytes; failures do not alter the input or the reusable Form. Unknown names, read-only fields, ambiguous checkbox appearances, XFA, signature fields and calculated forms fail explicitly. Field names currently require printable ASCII. Do not use with hostile inputs without host resource limits; dependency parsing occurs before form-tree limits.

This is an AcroForm semantic layer over `moonbitlang/pdflite@0.4.1`, not a PDF renderer. No OCR, scanned-form detection, encryption, signatures, JavaScript execution or flattening is implemented. A field value alone is insufficient: checkbox `/V` and every widget `/AS` must agree with existing `/AP` states.

Run `moon test --target wasm`, or select `wasm-gc`, `js`, `native`. Native tests must execute on a configured native C toolchain. Formatting and API files are produced by `moon fmt` and `moon info`.

For actual files, run `moon run bin/formferry --target wasm -- fields INPUT.pdf`, then `moon run bin/formferry --target wasm -- fill INPUT.pdf VALUES.json NEW.pdf`. A mapping accepts strings, booleans and `{ "select": "export" }` selectors. `batch INPUT.pdf RECORDS.json NEW_DIRECTORY` accepts an array of mappings. Existing output paths are refused. See [the complete example](samples/README.md); run `moon run samples/verify.mbtx wasm` for success, readback, overwrite rejection and recovery checks. A native CLI uses the same arguments with `--target native`.

The core is tested on Wasm, Wasm-GC and JavaScript locally. GitHub CI also executes native tests on Linux, macOS and Windows (MSVC). The first implementation baseline was moon 0.1.20261023 / moonc 0.10.17+d971670cd; CI follows the current stable `latest` compiler/core and pins the installer action. This is source distribution, not yet a Mooncakes release.

Text uses an explicit plain style: black Courier, template `/Q` horizontal alignment, up to 12pt with 2pt horizontal inset. This replaces the edited widget's normal appearance, rather than preserving its original typography. Printable ASCII (plus LF on Multiline fields) only; password/rich-text flags, rotated controls, rollover/down appearances, MaxLen violations and overflow fail. Comb has a dedicated fixed-cell profile. Non-ASCII text is rejected before any file is written. This profile does not promise arbitrary PDF or font compatibility.

Roadmap: scrolling and Unicode font policies; richer text styling; optional flattening. Capabilities are delivered as complete tested slices.
