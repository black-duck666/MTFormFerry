# Sources

Project code is a new implementation of the AcroForm workflow. PDF syntax, object IO and incremental writing use moonbitlang/pdflite 0.4.1, Apache-2.0, https://github.com/moonbitlang/office.mbt. The library is consumed as a dependency; its implementation is not copied here.

Semantic references: https://pdf-lib.js.org/docs/api/classes/pdfform (pdf-lib, MIT) and https://pypdf.readthedocs.io/en/stable/user/forms.html (pypdf, BSD-3-Clause). No implementation or fixtures from those projects have been copied. The small PDF in unit tests is a project-authored structural fixture.

Native/Wasm file IO and CLI verification scripts use moonbitlang/async 0.22.5, Apache-2.0, https://github.com/moonbitlang/async. Transitive dependency source and notices remain in their published packages (pdflite also depends on flate and x). The project registration template and its generator are original project fixtures under MIT. Sample project metadata comes from this repository's public name, owner and URL; the checkbox is illustrative.
