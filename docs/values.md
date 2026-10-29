# Reuse existing values

Run `moon run bin/formferry --target wasm -- values completed.pdf` to print a JSON mapping, or call `form.values_json()` in MoonBit. Use that mapping with `values_from_text` and `fill` against a fresh copy of the same template. This supports reviewing or correcting an application without retyping all existing values.

Values follow source field order; text is escaped as JSON, checkboxes become booleans and selections become `{"select":"export"}`. Absent values are omitted, distinct from an explicit empty string or unchecked value. Read-only fields are exported but cannot be written back through `fill`; exclude them deliberately when applying to another template. This is not a complete document backup.

The snapshot refuses unsupported field kinds, invalid current value encodings, unknown choice exports, contradictory choice indices and disagreement between button values and widget appearance states. It never silently skips unsupported controls. Existing `value(name)` remains a targeted read operation. The CLI writes JSON only to stdout, so callers choose their own output handling.
