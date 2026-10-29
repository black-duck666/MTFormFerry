# Multiline text

Fields with the PDF Multiline flag accept LF-separated printable ASCII strings through the existing `Text` API and JSON strings with `\n`. Input text, including explicit newlines and spaces, is retained in `/V`; only the display is hard-wrapped to the measured Courier character width. Every widget has a separate layout. Line spacing is 1.2 times the font size. Insufficient height rejects the entire fill instead of clipping text or truncating data.

CR/CRLF, tabs, rich text, passwords, comb fields and non-ASCII text remain unsupported and are rejected explicitly. Single-line fields continue to reject LF and retain their previous layout behavior. See `form/lines_wbtest.mbt` for a runnable two-line form, wrap-boundary, empty-value and overflow examples.
