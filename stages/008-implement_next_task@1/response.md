1. **Selected todo line**
   - `001 Inspect the current member message route, controller template, auth plugs, and existing route/feature tests around PageController.show_message/2.`

2. **Changes made**
   - Added `docs/iterations/012-member-receipt-detail-liveview-polish/inspection.md`.
   - The inspection documents:
     - current `GET /messages/:message_id?club_id=...` route and pipelines;
     - `:browser` and `:club_member_required` auth behaviour;
     - `PageController.show_message/2` loading/authorization/error semantics;
     - current HEEx template structure and stable receipt selectors;
     - `MemberReceiptPresentation` status mapping;
     - existing route/controller/feature/browser support test coverage;
     - LiveView conversion notes for later tasks.

3. **Validation commands run**
   - Attempted focused test command:
     - `PATH="$PWD/bin:$PATH" dev test web/test/memba_web/router_test.exs web/test/memba_web/controllers/page_controller_test.exs web/test/memba_web/controllers/member_message_detail_test.exs`
     - Result: failed before running tests because `dev` has no `test` subcommand.
   - Required full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed — `217 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 Inspect...`
     - to:
     - `- [x] 001 Inspect...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and conformed to:
     - ADR 0006: preserved/documented simple member-facing receipt vocabulary and operator-only detail separation.
     - ADR 0013: identified current feature-style/browser coverage and route/controller tests for user-visible behaviour.
     - ADR 0015: documented the current controller surface and LiveView migration constraints for member message detail pages.
   - No acceptance feature files were changed.