Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `012 Update smoke-tests/lib/config.js, smoke-test assertions, and smoke-tests/README.md so the default smoke address is everyone@test.clubs.memba.io and Postmark diagnostics look for that recipient.`

2. **Changes made**
   - Updated `smoke-tests/lib/config.js`
     - Default/generated smoke inbound address is now:
       - `everyone@${clubSlug}.${inboundDomain}`
       - defaulting to `everyone@test.clubs.memba.io`.
   - Updated `smoke-tests/features/step_definitions/inbound_club_email_steps.js`
     - Smoke configuration assertion now expects `everyone@test.clubs.memba.io`.
     - Existing Postmark diagnostics already use `world.config.inboundAddress`, so they now look for the new recipient automatically.
   - Updated `smoke-tests/README.md`
     - Required fixture inbound address now documents `everyone@test.clubs.memba.io`.
     - Postmark diagnostics docs now explicitly say they check the configured smoke recipient, defaulting to `everyone@test.clubs.memba.io`.
   - Added `smoke-tests/test/config.test.js`
     - Proves default smoke address generation.
     - Proves custom slug/domain still produce `everyone@<slug>.<namespace>`.

3. **Focused validation run**
   - `node --test smoke-tests/test/config.test.js` — passed, 2 tests.
   - `node --check smoke-tests/lib/config.js && node --check smoke-tests/features/step_definitions/inbound_club_email_steps.js && node --check smoke-tests/test/config.test.js` — passed.
   - `cd smoke-tests && NODE_PATH=../acceptance-tests/node_modules ../acceptance-tests/node_modules/.bin/cucumber-js --dry-run --format progress` — passed, 3 scenarios / 21 steps matched and skipped under dry-run.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed on the final working tree, 897 ExUnit tests / 0 failures.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Update ...`
   - To:
     - `- [x] 012 Update ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0020: Kept production smoke tests Fastmail-only and did not add alternate provider support.
   - ADR 0017: Preserved explicit production-path smoke diagnostics.
   - ADR 0016: Preserved Postmark-specific inbound diagnostics without changing provider architecture or introducing new HTTP clients.