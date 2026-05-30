Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.`

2. **Changes made**
   - Added stable IDs and/or accessible labels in:
     - `web/lib/memba_web/live/clubs_live/index.ex`
     - `web/lib/memba_web/live/clubs_live/show.ex`
     - `web/lib/memba_web/live/messages_live/show.ex`
   - Added selectors/labels for:
     - club/person/member/message forms and inputs
     - submit buttons
     - back links
     - stream/list containers
     - club/person/member/message rows
     - addressed recipient rows
     - delivery records and delivery status displays
     - member receipt rows and receipt status displays
   - Added PhoenixTest coverage in:
     - `web/test/memba_web/live/browser_acceptance_harness_test.exs`
   - Checked off only task `007` in:
     - `docs/iterations/005-browser-acceptance-harness/todo.md`

3. **Validation run**
   - `cd web && mix test test/memba_web/live/browser_acceptance_harness_test.exs --seed 0`
     - Failed before reaching assertions because Postgres was not running in the bare shell.
   - `cd web && mix format --check-formatted lib/memba_web/live/clubs_live/index.ex lib/memba_web/live/clubs_live/show.ex lib/memba_web/live/messages_live/show.ex test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `108 tests, 0 failures`.
   - Final `PATH="$PWD/bin:$PATH" dev check`
     - Passed again: `108 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.`
   - To:
     - `- [x] 007 Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: no shared `.feature` files were edited.
   - ADR 0013 respected: added/updated PhoenixTest coverage for web-facing behaviour.
   - Scope respected: no Cucumber step definitions, acceptance-test config, or `@todo-web` tagging changes were made; those remain for later unchecked tasks.