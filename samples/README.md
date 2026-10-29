# End-to-end: project registration

The same verification program now covers fixed-cell reference codes, schema export, aggregate validation, FDF export/import and locking completed fields. See `comb.json` and `lock.json` for authored field assignments/names. `export-fdf` followed by `fill-fdf` recreates the same bytes from the same template; `lock-complete` preserves rendering and causes subsequent updates to the named fields to fail. Run `moon run bin/formferry --target wasm -- help` for all commands.

For spreadsheet exports, run `moon run bin/formferry --target wasm -- batch-csv-complete samples/choices.pdf samples/batch.csv _build/csv-applications` after generating both templates. Each row produces a verified PDF, including the quoted multiline cell. See [CSV input rules](../docs/csv.md). `check FILE.pdf` lists missing Required fields; `values FILE.pdf` prints supported current values as JSON.

The template and its generator are project-authored, MIT licensed. The JSON contains the actual public repository name, owner and URL; `approved` is an example checkbox choice, not an external endorsement. No private infrastructure is needed. The library accepts other existing AcroForms within its documented profile; field names and values are not hardcoded in the fill engine.

From the repository root:

```
moon run samples/make_template.mbtx
moon run bin/formferry --target wasm -- fields samples/project.pdf
moon run bin/formferry --target wasm -- fill samples/project.pdf samples/project.json _build/registration.pdf
```

Replace `wasm` with `native` on a supported native toolchain. The command checks current values by reopening the produced bytes before publishing the output. It rejects an existing output or sibling `.formferry-part`, including when the output names the input. Failed writes remove their own temporary file. A full OS/power-loss durability guarantee is not claimed.

Open `_build/registration.pdf` in a PDF reader: all three strings and a tick must be visible. The controls remain interactive; unchanged page text and annotations remain. The original template is retained verbatim as the prefix of the incremental result. Try an unknown field, Chinese text, or an overlong URL: the command must fail without publishing an output. Run again with valid values and a fresh output path.

The template includes multiline notes, Required project/owner fields, centered project and right-aligned owner text. `moon run samples/make_choices.mbtx` creates a three-page variant with decision radio widgets, a delivery dropdown, a priority list and a multi-select materials list. The second batch record selects Send, Express, High priority, README and API guide. Choice fields also define defaults for the [reset workflow](../docs/reset.md). These authored sample choices describe the demonstration, not an external approval.

`samples/fit.json` uses the public URL of the template generator and four complete notes lines. Ordinary filling refuses the overflow; a trailing `--fit-text` enables bounded shrinking without truncation. Run `moon run samples/verify.mbtx wasm` to verify filling, fitting, JSON/CSV batches and default resets in one repeatable workflow.
