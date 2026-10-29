# Select several list items

MultiSelect list fields accept `Selections(["README", "examples"])` or JSON `{"materials":{"select":["README","examples"]}}`. A single-choice list continues to require `Selected(export)`. Use `choices(name)` to discover option order. Arrays must contain distinct known exports in that order; the writer rejects duplicates, unknown exports and reversed ordering instead of silently sorting a caller's data.

The writer synchronizes `/V`, ascending `/I`, `/TI = 0`, and highlights every selected row in every widget. All options must fit the full-list profile. Scrolling, sorted lists, arbitrary styles, Unicode and editable combos remain unsupported. A singleton selection roundtrips as `Selections([export])`; existing single-choice API and output remain unchanged.

`Selections([])` explicitly clears a multi-select list, removes `/V` and `/I` and draws no highlight. `value` then returns `None` and snapshots omit the absent value. Required completion refuses an empty selection. Clearing is rejected when a parent still supplies an inherited `/V`, because removing a local value would reveal that selection. Inputs are never silently dropped.

CSV multi-select cells contain JSON string arrays, with normal CSV quote escaping; see the last column of `samples/batch.csv`. Empty cells are invalid; use `[]` to clear. JSON batches, snapshots, readback verification and required checks share these semantics. Run `moon run samples/verify.mbtx wasm`: the third page of the second batch PDF shows README and API guide selected, with Examples unselected.

This extends the AcroForm workflow using the public [pdf-lib option-list semantics](https://pdf-lib.js.org/docs/api/classes/pdfoptionlist) as a reference (MIT). No upstream code or test fixtures are copied; implementation and authored samples are MIT.
