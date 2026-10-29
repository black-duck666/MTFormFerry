///|
/// Return missing Required fields in source order. Unsupported required controls raise.
/// FormFerry's completion policy treats Off, empty and space/LF-only text as missing.
pub fn Form::missing_required(self : Form) -> Array[String] raise {
  let missing = []
  for c in self.controls {
    if (c.flags & 2) == 0 {
      continue
    }
    let present = match self.checked_current(c) {
      Some(Text(s)) => !s.iter().all(ch => ch == ' ' || ch == '\n')
      Some(Checked(b)) => b
      Some(Selected(s)) => !s.is_empty()
      None => false
    }
    if !present {
      missing.push(c.info.name)
    }
  }
  missing
}
