# Fixed character cells

Text fields carrying Comb and a positive inherited MaxLen (at most 4096) place each printable ASCII character in its own equally spaced cell. This supports reference codes, postal codes and fixed-length application identifiers. Stored text, including spaces and escaped PDF punctuation, is unchanged. `/Q` selects left, centered or right placement within the available cells.

Comb cannot be combined with multiline, password or rich-text flags. Missing/invalid MaxLen, excess characters and cells too narrow for the font fail explicitly. `fit_text=true` may shrink characters using the same 6pt floor; it never drops characters. No cell borders or template artwork are invented.

Use ordinary text values through `fill`, JSON or CSV. Run `moon run bin/formferry --target wasm -- fill samples/choices.pdf samples/comb.json NEW.pdf` after generating the templates. The third page displays the illustrative eight-character reference FORM2026. `moon run samples/verify.mbtx wasm` exercises this example. Semantic reference: [pdf-lib comb text fields](https://pdf-lib.js.org/docs/api/classes/pdftextfield#enablecombing), MIT. Implementation and fixtures are authored under MIT; no upstream code copied.
