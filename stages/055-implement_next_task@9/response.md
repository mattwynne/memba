Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add or update LiveView/Phoenix tests for:`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_message_live/new_test.exs` with two compose-route authorization/selected-club tests:
     - signed-out visitors to `/messages/new?club_id=...` are redirected to `/auth` and the return path is preserved;
     - signed-in identities are forbidden when `/messages/new` is requested without a selected `club_id`.
   - Existing tests already covered the remaining task bullets:
     - no sender dropdown;
     - sender derived from current member and ignored sender params;
     - successful submit and success links;
     - send failure state/support copy;
     - club home CTA replacing inline compose.

3. **Focused validation**
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs test/memba_web/controllers/page_controller_test.exs'`
     - Result: `23 tests, 0 failures`
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted test/memba_web/live/member_message_live/new_test.exs'`
     - Result: passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `240 tests, 0 failures`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 009 Add or update LiveView/Phoenix tests for:`
   - To:
     - `- [x] 009 Add or update LiveView/Phoenix tests for:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0013 and ADR 0015.
   - Changes conform by adding Phoenix/LiveView route-auth coverage for the LiveView member compose flow, without moving member app behaviour back into controller implementation.