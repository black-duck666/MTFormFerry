# FormFerry · 笺舟

Fill existing PDF AcroForm controls from MoonBit. Checkboxes select existing appearance states; plain single-line text gets explicit Courier appearance streams. Saving appends an incremental update and retains the original bytes. Other controls remain untouched and cannot be filled.

Import `black-duck666/formferry/form`. Open bytes with `Form::open`, inspect `fields()`, then call `fill({ "approved": Checked(true) })`. Each call returns new bytes; failures do not alter the input or the reusable Form. Unknown names, read-only fields, ambiguous checkbox appearances, XFA, signature fields and calculated forms fail explicitly. Field names currently require printable ASCII. Do not use with hostile inputs without host resource limits; dependency parsing occurs before form-tree limits.

This is an AcroForm semantic layer over `moonbitlang/pdflite@0.4.1`, not a PDF renderer. No OCR, scanned-form detection, encryption, signatures, JavaScript execution or flattening is implemented. A field value alone is insufficient: checkbox `/V` and every widget `/AS` must agree with existing `/AP` states.

Run `moon test --target wasm`, or select `wasm-gc`, `js`, `native`. Native tests must execute on a configured native C toolchain. Formatting and API files are produced by `moon fmt` and `moon info`.

Text uses an explicit plain style: black Courier, left aligned, up to 12pt with 2pt horizontal inset. This replaces the edited widget's normal appearance, rather than preserving its original typography. Printable ASCII only; multiline, comb/password/rich-text flags, rotated controls, rollover/down appearances, MaxLen violations and overflow fail. Non-ASCII text is rejected before any file is written. This profile does not promise arbitrary PDF or font compatibility.

Roadmap: a file/JSON command workflow; choice controls and Unicode font policies; optional flattening. Capabilities are delivered as complete tested slices.
