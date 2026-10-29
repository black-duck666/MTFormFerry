# Dropdown fields

Non-editable single-selection combo fields (`/FT /Ch`, Combo flag) use `Selected(export)` and JSON `{ "customer": { "select": "exp" } }`. `choices(name)` returns exports in source order. A string option has the same export and label; a two-string option retains its distinct display label. Filling writes `/V` and `/I`, renders the display label with the documented Courier style and retains the original option definitions.

Unknown or duplicate exports, empty option sets, malformed options, editable combos, multi-selection/list boxes and non-ASCII labels are rejected. An unsuccessful choice does not publish output or poison the reusable Form. Runnable roundtrip and appearance tests are in `form/dropdown_wbtest.mbt`.
