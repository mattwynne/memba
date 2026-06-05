Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Keep the new index queries simple and deterministic; avoid implementing filters, pagination, bulk actions, or new statuses in this slice.`

2. **Changes made**
   - Wired `/admin/people` to `Memba.Membership.list_operator_people/0`.
   - Wired `/admin/messages` to `Memba.Messaging.list_operator_messages/0`.
   - Kept both indexes simple/read-only:
     - no filters;
     - no pagination;
     - no bulk actions;
     - no new status display/actions.
   - Added deterministic row rendering and data attributes for tests.
   - Added simple presentation fallbacks:
     - missing email → `—`;
     - no memberships → `No active memberships`;
     - missing message context → existing IDs / “Unknown …” labels.
   - Updated `web/test/memba_web/live/admin_operations_index_live_test.exs` to prove:
     - People rows render in deterministic query order with membership/email summaries;
     - Messages rows render newest-first with diagnostics links;
     - unsupported forms, filters, pagination, bulk actions remain absent.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/people_live/index.ex lib/memba_web/live/admin/messages_live/index.ex test/memba_web/live/admin_operations_index_live_test.exs`
     - Passed.
   - Direct focused test command hit the sandbox Postgres readiness issue:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin_operations_index_live_test.exs`
   - Reran focused tests inside `devenv shell` for that specific reason:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'bin/mix test test/memba_web/live/admin_operations_index_live_test.exs'`
     - Passed: `5 tests, 0 failures`.
   - Full validation because this changed browser-facing LiveView UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `520 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 006 Keep the new index queries simple and deterministic; avoid implementing filters, pagination, bulk actions, or new statuses in this slice.`
   - To:
     - `- [x] 006 Keep the new index queries simple and deterministic; avoid implementing filters, pagination, bulk actions, or new statuses in this slice.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADR files for this task.
   - The change keeps the existing architecture boundaries:
     - LiveViews call public context APIs only.
     - Query data comes from existing read-model/projection APIs.
     - No projection/event semantics changed.
     - No CRUD helpers, filters, pagination, bulk actions, or new statuses were introduced.