# Radio groups

`form.choices("answer")` lists the actual appearance export names. Fill with `Selected("No")`; JSON uses `{"answer":{"select":"No"}}`. Existing labels are not inferred or rewritten. The group `/V` is updated and every widget `/AS` is set either to its on-state or Off. A subsequent fill can choose a different widget.

Supports distinct existing normal on/off appearance streams. Unknown choices, repeated export names, RadiosInUnison and an `/Opt` export mapping are rejected. Clearing to Off is intentionally not exposed, including for NoToggleToOff groups. Read-only handling, incremental preservation and transaction isolation are unchanged. See `form/radio_wbtest.mbt` for a runnable two-widget example and boundary tests.
