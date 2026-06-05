Implemented the next unchecked task.

1. **Selected todo line**
   - `009 Remove the staff send-message form, its form assign/event handling, and any no-longer-needed member sender options from club detail.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/clubs_live/show.ex`:
     - Removed staff-side club message compose form markup:
       - `#new-message-form`
       - `#message-sender-select`
       - `#message-subject-input`
       - `#message-body-input`
       - `#send-message-button`
     - Removed `handle_event("send_message", ...)`.
     - Removed `@empty_message`, `@message_form`, `@member_options`, `member_options/1`, and the now-unused message refresh helper.
     - Kept the embedded existing messages list intact for task `010`.
   - Updated `web/test/memba_web/live/admin/clubs_live/show_test.exs`:
     - Added LiveView coverage asserting the staff club page no longer offers message composition.
   - Updated `web/test/memba_web/live/browser_acceptance_harness_test.exs`:
     - Replaced expectations for the staff message form with absence assertions.
     - Reworked message diagnostics setup to create an existing club message through the domain API instead of the removed staff UI composer.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/clubs_live/show.ex test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Failed before tests due the known sandbox Postgres socket readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
     - Passed: `12 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `523 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 009 Remove the staff send-message form, its form assign/event handling, and any no-longer-needed member sender options from club detail.`
   - To:
     - `- [x] 009 Remove the staff send-message form, its form assign/event handling, and any no-longer-needed member sender options from club detail.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADR files, and no `docs/adr/` files are present in this workspace.
   - Implementation remains in Phoenix LiveView.
   - No Membership or Messaging domain semantics were changed.
   - Member-side message composition remains untouched.
   - Staff-side message composition was removed without adding a replacement composer, preserving the iteration’s read-only staff operations direction.
   - Existing message diagnostics/listing was left in place for the separate task `010`.