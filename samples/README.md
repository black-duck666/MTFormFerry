# End-to-end: project registration

The template and its generator are project-authored, MIT licensed. The JSON contains the actual public repository name, owner and URL; `approved` is an example checkbox choice, not an external endorsement. No private infrastructure is needed. The library accepts other existing AcroForms within its documented profile; field names and values are not hardcoded in the fill engine.

From the repository root:

```
moon run samples/make_template.mbtx
moon run bin/formferry --target wasm -- fields samples/project.pdf
moon run bin/formferry --target wasm -- fill samples/project.pdf samples/project.json _build/registration.pdf
```

Replace `wasm` with `native` on a supported native toolchain. The command checks current values by reopening the produced bytes before publishing the output. It rejects an existing output or sibling `.formferry-part`, including when the output names the input. Failed writes remove their own temporary file. A full OS/power-loss durability guarantee is not claimed.

Open `_build/registration.pdf` in a PDF reader: all three strings and a tick must be visible. The controls remain interactive; unchanged page text and annotations remain. The original template is retained verbatim as the prefix of the incremental result. Try an unknown field, Chinese text, or an overlong URL: the command must fail without publishing an output. Run again with valid values and a fresh output path.
