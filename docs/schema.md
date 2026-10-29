# Build an input screen from the actual template

`form.schema_json()` and `formferry schema INPUT.pdf` export a version-1 metadata object with fields in source order. It includes exact names/kinds, read-only and Required flags, supported/writable classification, text MaxLen and implementation limit, multiline/Comb/alignment settings, and choice exports with their real display labels. Multi-select fields are marked explicitly. Radio labels are null because appearance exports do not establish a human label.

Use this to construct a field mapper or review screen, then call `validate` with entered values and finally `fill`. The export is FormFerry metadata, not the JSON Schema standard. `writable` classifies type/flags/read-only status; it cannot guarantee every value fits a widget or that all appearance structures are valid. Unsupported controls remain listed. Malformed constraints/options fail instead of producing guessed metadata. No values or document contents are copied into the schema.

Run `moon run bin/formferry --target wasm -- schema samples/choices.pdf`. For delivery, export `exp` maps to label `Express`; materials is multiple and code has eight Comb cells. This workflow requires no UI framework or private infrastructure.
