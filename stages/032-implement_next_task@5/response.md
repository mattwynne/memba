1. **Selected todo line**
   - `005 Update request form rendering:`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/get_started.html.heex`
     - For a signed-in identity with **no existing Person**, the request form now collects:
       - requester name
       - group/club name
       - note
     - It no longer renders a typed `request[requester_email]` field.
     - The verified signed-in email remains shown read-only in the existing “You’ve verified your email” panel.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`
     - Strengthened the signed-in/no-Person Get Started rendering test to assert:
       - verified email is displayed;
       - requester name is collected;
       - requester email input is not rendered.
     - Existing signed-in/existing-Person rendering coverage continues to verify name/email are read-only and only club/note are collected.

3. **Focused validation run**
   - First ran the updated focused test before the template change and confirmed it failed because the typed requester email field was still rendered.
   - Passed:
     - `PATH="/nix/store/vly1mpb0rah7xr34ybcf3s339cjh22vh-postgresql-17.9/bin:$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/page_controller_test.exs:962 test/memba_web/controllers/page_controller_test.exs:1003 --seed 0`
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/controllers/page_html/get_started.html.heex test/memba_web/controllers/page_controller_test.exs`
     - `PATH="/nix/store/vly1mpb0rah7xr34ybcf3s339cjh22vh-postgresql-17.9/bin:$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/page_controller_test.exs --seed 0`
       - `38 tests, 0 failures`
     - `git diff --check`
   - Also attempted required broad browser-facing validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: **failed** in the browser acceptance suite on an existing/pending iteration mismatch: `request_account` still expects the old signed-out request form (`#get-started-request-form`) before the later planned Cucumber/step-definition updates. I did not fix that here because tasks 013–014 explicitly cover that acceptance plumbing/tag narrowing.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Update request form rendering:`
   - To:
     - `- [x] 005 Update request form rendering:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: kept the work inside the Phoenix application.
   - ADR 0013: used existing controller/LazyHTML tests for controller-rendered Get Started HTML, consistent with using lower-level Phoenix tests where they clearly expose rendering details.
   - ADR 0010: did not edit shared acceptance feature files during this rendering-only task; those remain for the later planned acceptance tasks.