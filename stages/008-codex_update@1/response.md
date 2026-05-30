### Files changed
- `.fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md`

### Summary of edits
I applied targeted plan-only clarifications to close the synthesis-identified spec gaps without changing scope or starting implementation:

1. **Scope (In scope)**
   - Added explicit behavior for `recipient_name`/`recipient_email` when nil/empty: emit empty CSV fields.
   - Added explicit CSV response requirements:
     - UTF-8 encoding via `Content-Type: text/csv; charset=utf-8`
     - `Content-Disposition: attachment` with filename `message_{message_id}_delivery_receipts.csv`

2. **Acceptance Criteria**
   - Added **zero-recipient case**: header row only, no data rows.
   - Added **nil/empty recipient field behavior**: empty CSV fields.
   - Added explicit **UTF-8 Content-Type** criterion.
   - Added explicit **Content-Disposition + filename** criterion.

3. **Implementation Plan**
   - Tightened step 2 to a **Messages context-facing export function**, while still allowing a helper module per existing conventions (no hard architecture invention).
   - Expanded step 6 test list to include:
     - nil/empty recipient field rendering (when representable),
     - zero-recipient output,
     - response headers/filename,
     - UTF-8 content.

4. **Validation Plan**
   - Added manual verification for headers/filename.
   - Added manual verification for zero-recipient output, nil/empty field behavior (when representable), and non-ASCII UTF-8 handling.

---

### Opus instructions applied
- ✅ Edit plan only; no implementation work.
- ✅ Add AC for nil/empty recipient field behavior.
- ✅ Add AC for zero-recipient/header-only behavior.
- ✅ Add AC for Content-Type, Content-Disposition, and filename.
- ✅ Add UTF-8 note/criterion.
- ✅ Tighten implementation step 2 toward context-facing Messages API without forcing a major design decision.
- ✅ Update validation plan for the newly explicit checks.
- ✅ Kept scope boundaries intact (no auth/reporting/background/domain changes).

---

### Instructions skipped (need Matt’s judgment)
- **None skipped.**  
  All requested fixes were applied in a way that avoids introducing new product or architecture decisions.

---

### Recheck attention points
- Confirm the phrasing **“when representable in existing read models”** for nil/empty recipient fields is acceptable and sufficiently non-speculative.
- Confirm the filename requirement `message_{message_id}_delivery_receipts.csv` is exactly what downstream reviewers expect.
