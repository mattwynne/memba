Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `012 Remove the legacy POST /?club_id=<club_id> send route and controller action in this slice once the LiveView submit path is covered. Do not keep a parallel member send endpoint unless a test reveals an existing non-UI caller that must be preserved.`

2. **Changes made**
   - Removed the legacy `post "/", PageController, :send_message` route from `web/lib/memba_web/router.ex`.
   - Removed `PageController.send_message/2` from `web/lib/memba_web/controllers/page_controller.ex`.
   - Removed leftover inline-compose controller plumbing:
     - `message_params` support in `render_club_home/2`
     - `put_default_sender/2`
     - `format_reason/1`
     - obsolete `:member_options` / `:message_form` assigns for the removed inline form
   - Added router coverage in `web/test/memba_web/router_test.exs` proving `POST /` no longer routes.

3. **Focused validation run**
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba_web/router.ex lib/memba_web/controllers/page_controller.ex test/memba_web/router_test.exs'`
     - Passed.
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/router_test.exs'`
     - Passed: `9 tests, 0 failures`.
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/controllers/page_controller_test.exs'`
     - Passed: `14 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `243 tests, 0 failures`.

4. **Todo check-off made**
   - Changed task `012` from `- [ ]` to `- [x]`.
   - Left task `013` unchecked.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR/project conformance**
   - The plan does not explicitly reference ADR files for this task.
   - Followed the Phoenix routing/controller guidance and kept the member send path solely in the LiveView flow.
   - Did not preserve or introduce a parallel member send endpoint.
   - Existing focused controller/router coverage and full `dev check` are passing.