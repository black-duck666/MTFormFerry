# Preserve template alignment

Text fields honor PDF `/Q`: 0 is left, 1 center and 2 right. The field's nearest inherited setting wins, followed by the AcroForm default and finally left alignment. Each wrapped multiline row is measured and aligned independently using the same Courier advance as overflow detection. Stored `/V` values, spaces, explicit line breaks and MaxLen behavior are unchanged.

Non-integer or out-of-range `/Q` fails with the field name. The writer does not guess how an unsupported setting should display. This preserves horizontal alignment within the documented plain Courier style; it does not preserve arbitrary fonts, colors, rich text or vertical layout. Choice labels retain their separate left-aligned appearance profile.

Run `moon run samples/verify.mbtx wasm`. In the first page of `completed.pdf`, the project value is centered and the owner is right aligned; source stays left aligned. The template and sample data are authored under MIT. Semantic reference: [pdf-lib PDFTextField alignment API](https://pdf-lib.js.org/docs/api/classes/pdftextfield#getalignment), MIT; no code or fixtures copied.
