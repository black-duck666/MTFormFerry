# Start again from template defaults

Use `form.reset(["notes", "delivery"])` to reset selected writable fields. It returns a new incrementally saved PDF after checking every reset value and button state by reopening it. Names must be distinct and known; output order follows the source field tree regardless of name-array order. Unselected fields, option definitions, defaults and original bytes remain intact. Failures leave the reusable Form unchanged.

The nearest inherited `/DV` supplies the default. Text, checkbox, radio, dropdown, single-list and multi-list defaults go through the same validation and appearance generation as ordinary filling. Without a default, text becomes an explicit empty string, checkboxes become Off, radios have `/V /Off` and every widget Off, and choices lose `/V` and `/I` while drawing an empty selection. Resetting a radio may restore Off even with NoToggleToOff because this operation resets a field rather than simulating a click. Multi-default arrays must follow option order.

Read-only/unsupported fields, invalid default types, unknown exports, text overflow and unsafe clearing of inherited choice `/V` are refused. The latter avoids exposing a parent's old selection when removing a local value. `complete=true` optionally enforces Required fields after reset; `fit_text=true` optionally fits text defaults using the existing 6pt policy. Reset retains historical revisions and is not data erasure or sanitization.

After generating a CSV batch, run `moon run bin/formferry --target wasm -- reset _build/csv-applications/0002.pdf samples/reset.json _build/reset.pdf`. The second page returns to Keep/Standard/Normal; the third page selects only README; notes become empty and project/owner/source remain as filled. Existing output paths are refused. `moon run samples/verify.mbtx wasm` includes reset success, readback, overwrite refusal and an invalid field that publishes no file.

The `/DV` meaning is documented by [pypdf's form guide](https://pypdf.readthedocs.io/en/stable/user/forms.html), BSD-3-Clause; no implementation or fixtures copied. Code, names file and authored default-bearing template are MIT.
