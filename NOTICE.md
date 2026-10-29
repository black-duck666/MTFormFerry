# Sources

Comb semantics also refer to https://pdf-lib.js.org/docs/api/classes/pdftextfield#enablecombing (pdf-lib, MIT). FDF value exchange refers to Adobe's Forms overview and the Forms Data Format section of its PDF reference: https://opensource.adobe.com/dc-acrobat-sdk-docs/library/overview/Overview_Forms.html. The existing pdflite dependency supplies syntax/classic-xref IO; FDF workflow logic and tests are project-authored. No additional implementation or fixture code is copied.

Additional format reference: Adobe's public PDF 1.7 reference / ISO 32000-1:2008, section 12.7: https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf. The reference is not redistributed; no text or implementation is copied. FormFerry documents its own stricter completion policy separately.

Project code is a new implementation of the AcroForm workflow. PDF syntax, object IO and incremental writing use moonbitlang/pdflite 0.4.1, Apache-2.0, https://github.com/moonbitlang/office.mbt. The library is consumed as a dependency; its implementation is not copied here.

Semantic references: https://pdf-lib.js.org/docs/api/classes/pdfform (pdf-lib, MIT) and https://pypdf.readthedocs.io/en/stable/user/forms.html (pypdf, BSD-3-Clause). No implementation or fixtures from those projects have been copied. The small PDF in unit tests is a project-authored structural fixture.

Choice-list semantics were also compared with https://pdf-lib.js.org/docs/api/classes/pdfoptionlist and its linked PDFAcroChoice source (pdf-lib, MIT). The measured full-list appearance and refusal of scrolling are FormFerry's implementation profile; no upstream implementation or test fixture was copied. CSV syntax refers to https://www.rfc-editor.org/rfc/rfc4180; the private decoder and its tests were authored for the form import workflow.

Native/Wasm file IO and CLI verification scripts use moonbitlang/async 0.22.5, Apache-2.0, https://github.com/moonbitlang/async. Transitive dependency source and notices remain in their published packages (pdflite also depends on flate and x). The project registration template and its generator are original project fixtures under MIT. Sample project metadata comes from this repository's public name, owner and URL; the checkbox is illustrative.
