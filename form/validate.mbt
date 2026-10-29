///|
pub(all) struct ValidationIssue {
  field : String
  message : String
} derive(Eq, Debug)

///|
/// Collect field errors without saving. Final fill may still fail during serialization/IO.
pub fn Form::validate(
  self : Form,
  values : Map[String, Value],
  complete~ : Bool = false,
  fit_text~ : Bool = false,
) -> Array[ValidationIssue] raise {
  let issues = []
  let mut sandbox = @pdf.pdf_read_document_from_bytes(self.original)
  for c in self.controls {
    let key = c.info.name
    let candidate = values.get(key)
    if candidate is Some(v) {
      let valid = try {
        write_value(sandbox, c, v, fit_text)
        true
      } catch {
        e => {
          issues.push({ field: key, message: e.to_string(), })
          false
        }
      }
      if !valid {
        // Discard partial appearance writes before validating another field.
        sandbox = @pdf.pdf_read_document_from_bytes(self.original)
        continue
      }
    }
    if complete && (c.flags & 2) != 0 {
      let current = match candidate {
        Some(v) => Some(v)
        None =>
          self.checked_current(c) catch {
            e => {
              issues.push({ field: key, message: e.to_string(), })
              continue
            }
          }
      }
      if !value_present(current) {
        issues.push({ field: key, message: "required field is empty", })
      }
    }
  }
  let unknown = []
  for key, _ in values {
    if !self.controls.any(c => c.info.name == key) {
      unknown.push(key)
    }
  }
  unknown.sort()
  for key in unknown {
    issues.push({ field: key, message: "unknown field", })
  }
  issues
}

///|
pub extend ValidationIssue with Eq::{equal, not_equal}

///|
pub extend ValidationIssue with Debug::{to_repr}
