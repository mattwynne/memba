Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Move the existing message detail loading and authorization logic into a clear LiveView mount path or supporting context/helper:`

2. **Changes made**
   - Added `MembaWeb.MemberMessageDetail`
     - Centralizes member message detail loading for the LiveView.
     - Requires a valid selected club from the signed-in identity’s active clubs.
     - Loads the message and verifies `message.club_id == club_id`.
     - Returns `{:error, :forbidden}` for missing/invalid/unauthorized club selection.
     - Returns `{:error, :not_found}` for missing messages or club/message mismatches.
     - Preserves the existing receipt/sender assigns used by the current template.
   - Updated `MembaWeb.MemberMessageLive.Show`
     - Mount now delegates detail loading/authorization to `MemberMessageDetail.load/2`.
     - Preserves existing not-found handling via `Phoenix.Router.NoRouteError`.
     - Uses a 403-capable exception for LiveView mount-time forbidden handling.
   - Added `MembaWeb.ForbiddenError`
     - Plug-compatible exception with `plug_status: 403`.
   - Cleaned up `MembaWeb.PageController`
     - Removed now-unused `show_message/2` controller loading logic and its private helper duplication.
   - Added `MembaWeb.MemberMessageDetailLoaderTest`
     - Covers successful detail assign loading.
     - Covers forbidden outcomes for missing, invalid, and unauthorized selected clubs.
     - Covers not-found outcomes for missing messages and club/message mismatches.

3. **Validation**
   - `cd web && mix format --check-formatted lib/memba_web/forbidden_error.ex lib/memba_web/member_message_detail.ex lib/memba_web/live/member_message_live/show.ex lib/memba_web/controllers/page_controller.ex test/memba_web/member_message_detail_loader_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `222 tests, 0 failures`.
   - Note: a direct `mix test ...` attempt outside the dev-managed Postgres environment failed because the standalone Postgres socket was unavailable; `dev check` was then run successfully with required services.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Move the existing message detail loading and authorization logic into a clear LiveView mount path or supporting context/helper:`
   - To:
     - `- [x] 004 Move the existing message detail loading and authorization logic into a clear LiveView mount path or supporting context/helper:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015: member message detail loading now belongs to the LiveView path/helper rather than the controller route.
   - ADR 0013: added focused automated tests for the user-facing loading/authorization behaviour.
   - ADR 0006: preserved the existing member-facing receipt vocabulary by continuing to use `MembaWeb.MemberReceiptPresentation`; no operator-only fields were added to member-facing output.