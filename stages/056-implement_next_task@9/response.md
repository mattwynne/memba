Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Apply auth gates:`

2. **Changes made**
   - Applied staff auth gate to `/admin/*`:
     - Added `plug :require_staff_identity` to the `:staff_browser` pipeline.
     - Wrapped admin LiveViews in `live_session :staff_admin` with `on_mount: [{MembaWeb.UserAuth, :require_staff_identity}]`.
   - Applied member auth gate for temporary `?club_id=...` club/member entry points:
     - Added `MembaWeb.UserAuth.require_active_club_member_if_club_id_present/2`.
     - Routed `/` through a `:club_member_context` pipeline so `/` remains public normally, but `/?club_id=<uuid>` requires active membership.
   - Added route-level auth gate tests in `web/test/memba_web/auth_gates_test.exs` for:
     - unauthenticated admin redirect with return path,
     - signed-in non-staff admin forbidden,
     - signed-in staff admin allowed,
     - unauthenticated `club_id` route redirect with return path,
     - signed-in non-member `club_id` route forbidden,
     - signed-in active member `club_id` route allowed.
   - Updated existing admin feature-style tests to sign in as staff before visiting `/admin/*`.
   - Added `sign_in_staff/2` helper to `MembaWeb.FeatureCase`.

3. **Validation commands run**
   - `cd web && mix format`
     - Passed.
   - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `189 tests, 0 failures`.
   - `git diff --check`
     - Passed with no whitespace errors.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Apply auth gates:`
   - To:
     - `- [x] 009 Apply auth gates:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / project conformance**
   - No ADR files were present under `docs/adr/`.
   - Followed local Phoenix routing/LiveView guidance:
     - route gates are applied in router pipelines,
     - LiveView admin routes use `live_session` `on_mount` auth protection,
     - public `/` remains available for unauthenticated marketing traffic unless a `club_id` query parameter selects the temporary member context.
   - No acceptance `.feature` files were changed.
   - No new HTTP client usage was introduced.