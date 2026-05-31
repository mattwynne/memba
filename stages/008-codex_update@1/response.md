### Files changed

- `docs/iterations/009-routing-and-liveview-surface-split/plan.md`

### Summary of edits

I made the requested plan-only clarity updates without changing scope or intent:

1. **Finalized legacy-route behavior in acceptance criteria**
   - Changed old harness route criterion from “no longer reaches old pages” to explicit behavior:
     - **returns normal 404 page**
     - **no redirects**

2. **Aligned implementation steps with finalized routing decision**
   - Updated router step to explicitly use an `/admin` scope with a **`:staff_browser` pipeline** that currently mirrors `:browser`.
   - Updated route-test step to assert old harness paths return **404, not redirects**.

3. **Converted “Open Technical Decisions” into finalized decisions**
   - Renamed section:
     - `## Open Technical Decisions` → `## Technical Decisions`
   - Rewrote the three bullets from “Whether... Prefer...” into direct decisions:
     - move LiveView files into `live/admin/...`
     - introduce `:staff_browser` pipeline now
     - implement real `Layouts.club_site` seam with default theme assigns

4. **Kept validation language consistent**
   - Updated automated validation bullet to say old harness routes return **404 (no redirects)**.
   - Updated manual smoke step 7 to confirm `/clubs` returns normal 404 and does not render club list.

### Which Opus instructions were applied

Applied all obvious requested fixes reflected in prior reviews:

- Rename “Open Technical Decisions” to finalized decisions section.
- Convert preference wording into finalized decision wording.
- Specify explicit legacy-route behavior (404 vs redirect) in acceptance/validation details.

### Instructions skipped (require Matt’s judgment)

- **None.** All requested edits were objective and applied directly.

### Notes for Opus recheck

- The plan now explicitly resolves the prior ambiguity around legacy routes and technical decision finality.
- No new scope, policy, or implementation detail was introduced beyond what was already implied by the existing plan and review guidance.