1. **Selected todo line**
   - `- [ ] 012 Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.`

2. **Changes made for this task**
   - Updated member-facing delivery presentation:
     - `pending`, `dispatching`, and `failed` now present as the softened member-facing `sent` / “Sending” status.
     - Detailed provider statuses (`delayed`, `bounced`, `spam_complaint`, `spam complaint`) now fold into `delivery problem`.
     - This prevents raw infrastructure/provider lifecycle states from leaking into member-facing copy.
   - Updated staff/operator diagnostics:
     - Admin message detail now shows dispatch diagnostics from `EmailDelivery` records:
       - exact dispatch status,
       - attempt count,
       - latest error,
       - latest detail.
     - Admin deliveries overview now includes a separate “Dispatch” column with exact async dispatch status/error while preserving existing provider status/reason columns.
     - Added virtual fields to the staff delivery projection schema for joined dispatch diagnostics.
     - Extended `Messaging.list_operator_deliveries/1` to join `EmailDelivery` dispatch state into operator rows.
   - Added/updated focused tests:
     - Member presentation test proves raw async/provider statuses are folded into member-safe statuses.
     - Admin diagnostics test proves staff/operator views show exact failed dispatch status/error while member receipt status remains softened.

3. **Validation commands/results**
   - Formatting check:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted ...`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba_web/member_email_delivery_presentation_test.exs test/memba_web/live/admin_diagnostics_live_test.exs test/memba_web/live/deliveries_live_test.exs'`
     - Passed: `13 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.
   - Full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Failed in the acceptance suite: `82 scenarios (6 failed, 76 passed)`.
     - These failures remain for the later unchecked test/final-validation tasks (`013`/`014`), consistent with the previous known async-delivery acceptance/test update gap.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.`
   - To:
     - `- [x] 012 Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0006: member-facing delivery status stays simplified and avoids provider/infrastructure terminology.
   - ADR 0007: changes remain inside Messaging-owned read models/projections and web presentation; no cross-context write boundary changes.
   - ADR 0021: existing read-model projection/diagnostics boundaries are preserved; this task only presents committed read-model state and joined operator diagnostics.