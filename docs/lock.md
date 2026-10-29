# Mark completed fields read-only

`form.lock(["project", "owner"], complete=true)` sets the standard ReadOnly bit on named terminal fields after checking the Required completion policy. Omit complete to permit locking a draft. The writer retains every other effective flag, including inherited flags, and preserves values, appearances, defaults and unselected fields. Names must be known, distinct and within the 4096-field limit. Already-read-only selections return original bytes when no changes are needed.

Run `moon run bin/formferry --target wasm -- lock-complete FILLED.pdf samples/lock.json NEW.pdf`. `lock` permits drafts. The operation reopens output and verifies the selected flags and unchanged field dictionaries before publishing. Subsequent FormFerry fill/reset calls refuse the read-only fields. Run `moon run samples/verify.mbtx wasm` for the completed batch → lock → refused overwrite workflow.

ReadOnly is a viewer interaction hint. It is not encryption, a signature, flattening or tamper protection, and other software can remove it. Controls remain interactive for unselected fields. Historical revisions remain in the incrementally saved file. No visual appearance regeneration or removal of values occurs.
