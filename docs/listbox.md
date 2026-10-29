# Single-selection lists

`Kind::Listbox` identifies `/FT /Ch` fields without Combo. Use `choices(name)` and `Selected(export)` exactly as for dropdowns, including JSON selectors and CSV choice cells. `fill` writes the export to `/V`, the selected zero-based index to `/I`, and `/TI = 0`. The original options and unedited fields remain intact. Value snapshots and completion checks understand the new kind.

Each widget gets a full Courier list appearance: all labels appear in source order, with a light gray background behind the selected row and black text. Every label must fit horizontally and every row must fit vertically. A too-small widget is rejected rather than showing a clipped or misleading selection. All widgets belonging to the same field are updated. The normal appearance is replaced with this explicit plain style.

Single-selection flags are ReadOnly, Required and NoExport; ReadOnly writes remain refused. MultiSelect uses the separate [array-selection workflow](multiselect.md). Sort, editable/combo flags, rollover/down appearances, rotated controls, invalid options/indices and Unicode labels are rejected. Scrolling remains planned. Existing `/TI` is reset to zero because this profile displays the entire list; no options are discarded.

Run `moon run samples/verify.mbtx wasm`, or generate both templates and run the [CSV workflow](csv.md). The second page of `0002.pdf` must show `High priority` highlighted while `Normal` and `Deferred` remain visible. The example is an authored delivery-priority form and requires no private infrastructure. Structural tests check V/I/TI, label operators, multiple widgets, overflow, deterministic output, unchanged bytes, snapshot round trips and recovery.
