1. **Selected todo line**
   - `008 Add focused tests for member route authorization, message-club ownership checks, status label/icon mapping, and no operator-only fields on member pages.`

2. **Changes made**
   - Added `web/test/memba_web/controllers/member_message_detail_test.exs`.
   - Covered focused member message detail behaviours:
     - signed-in inactive members are forbidden and do not see message content;
     - a message requested through the wrong `club_id` returns not found without leaking content;
     - all member-facing receipt statuses render with expected labels and Heroicons:
       - `sent` → `Sending` / `hero-clock`
       - `delivered` → `Delivered` / `hero-check-circle`
       - `delivery problem` → `Delivery problem` / `hero-exclamation-triangle`
       - `opened` → `Opened` / `hero-envelope-open`
     - stable member receipt rows expose recipient/status test selectors;
     - member message detail hides operator-only fields such as delivery IDs, recipient email address, provider channel, raw provider status, provider reason, delivery records, and admin links.
   - Checked off only task `008` in `docs/iterations/011-member-facing-message-behaviour/todo.md`.

3. **Focused validation run**
   - `devenv shell -- bash -lc 'mix test test/memba_web/controllers/member_message_detail_test.exs test/memba_web/controllers/page_controller_test.exs test/memba_web/member_receipt_presentation_test.exs'`
     - Passed: `21 tests, 0 failures`
   - `devenv shell -- bash -lc 'mix format --check-formatted && mix compile --warnings-as-errors'`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `217 tests, 0 failures`
   - `git diff --check`
     - Passed
   - whitespace check for the new untracked test file
     - Passed

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 008 Add focused tests for member route authorization, message-club ownership checks, status label/icon mapping, and no operator-only fields on member pages.`
   - To:
     - `- [x] 008 Add focused tests for member route authorization, message-club ownership checks, status label/icon mapping, and no operator-only fields on member pages.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Tests remain within the Phoenix application.
   - ADR 0006: Tests prove member-facing delivery language stays simplified while operator/provider detail remains hidden.
   - ADR 0013: Added focused Phoenix web/controller tests using existing project test helpers and stable selectors.