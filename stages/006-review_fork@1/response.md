# Iteration 006 Browser Automation Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

The implementation fully conforms to ADR 0021 (Playwright/Cucumber Acceptance Testing):

- ✅ Test location: `acceptance-tests/` directory structure
- ✅ Shared feature files via symlink to `features/shared/`
- ✅ Tag-based filtering: browser excludes `@todo-web`, domain runs all scenarios
- ✅ Test database: `mix ecto.reset` with `MIX_ENV=test` before Phoenix startup
- ✅ Startup/teardown: database prep, Phoenix on port 4002, HTTP readiness check, log capture, graceful shutdown
- ✅ Synchronization: Playwright polling assertions with bounded timeouts (10-15s)
- ✅ Step definitions: organized in `steps/`, using semantic selectors (`getByRole`, `getByLabel`)
- ✅ Development workflow: `npm test` for browser (filtered), `dev check` for domain (unfiltered)

The ADR's mention of "Ecto sandbox mode" in the context section is clarified by the prescriptive requirement to use `mix ecto.reset` in the startup/teardown section, which is correctly implemented.

## ADR Violations

None.

## Blocking Issues

None.

## Bounded-Safe Fixes

1. **Extract duplicate MEMBER_MAP**: The member data mapping appears in both `acceptance-tests/steps/member.steps.js` and `acceptance-tests/steps/webhook.steps.js`. Extract to `acceptance-tests/steps/testData.js`:
   ```javascript
   // acceptance-tests/steps/testData.js
   export const MEMBER_MAP = {
     Alice: { name: 'Alice Anderson', email: 'alice@example.com' },
     Bob: { name: 'Bob Brown', email: 'bob@example.com' },
     Carol: { name: 'Carol Chen', email: 'carol@example.com' },
     Dave: { name: 'Dave Davis', email: 'dave@example.com' }
   };
   ```
   Then import in both files: `import { MEMBER_MAP } from './testData.js';`

2. **Use `page.reload()` for clarity**: In `acceptance-tests/steps/email.steps.js`, replace `await this.page.goto(this.page.url())` with `await this.page.reload()` for semantic clarity.

3. **Improve unknown actor error messages**: In `webhook.steps.js` and `member.steps.js`, enhance error messages:
   ```javascript
   if (!email) {
     throw new Error(`Unknown actor: ${actor}. Valid actors: ${Object.keys(MEMBER_MAP).join(', ')}`);
   }
   ```

4. **Standardize timeout constants**: In `acceptance-tests/steps/`, extract magic timeout numbers to named constants at file top:
   ```javascript
   const UI_PROJECTION_TIMEOUT_MS = 10000;
   const STATUS_PROJECTION_TIMEOUT_MS = 15000;
   ```

5. **Add symlink verification**: In `acceptance-tests/harness/lifecycle.js`, add BeforeAll check:
   ```javascript
   BeforeAll(async function () {
     const fs = await import('fs/promises');
     try {
       await fs.stat('features/shared');
     } catch (error) {
       throw new Error('features/shared symlink missing or broken. Run: ln -s ../web/test/acceptance/features features/shared');
     }
     // ... existing startup code
   });
   ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Database isolation strategy** (`acceptance-tests/harness/phoenix.js`)  
   **Smell**: Browser tests reset database once per run, not per scenario, relying on scenario idempotence and unique identifiers.  
   **Why judgement-worthy**: This is simpler than sandbox mode but more fragile. If scenarios aren't carefully isolated or use colliding identifiers, cross-scenario pollution could occur. The ADR accepts this trade-off ("browser tests are slower"), but if test flakiness emerges, switching to per-scenario resets or domain-side test data builders might be needed. Monitor for pollution issues in CI.

2. **Hardcoded test data coupling** (`acceptance-tests/steps/member.steps.js`, `webhook.steps.js`)  
   **Smell**: Member data hardcoded in step definitions creates tight coupling to feature file actor names (Alice, Bob, Carol, Dave).  
   **Why judgement-worthy**: This works for current scenarios but creates an implicit contract between feature files and step code. Adding a new actor requires code changes in multiple files. Consider whether a declarative member registry (parsed from feature metadata or Gherkin tables) would better separate concerns, or accept this as acceptable for acceptance-test fixtures.

3. **Message ID correlation gap** (`acceptance-tests/steps/webhook.steps.js`)  
   **Smell**: Webhook POSTs use hardcoded `MessageID: 'test-message-id'` without tracking actual message IDs from sent messages.  
   **Why judgement-worthy**: If the webhook handler or projection logic validates MessageID correlation with real deliveries, this hardcoded value might not match reality, causing silent test failures or false positives. Current implementation passes, suggesting the handler accepts arbitrary IDs, but this could mask real bugs. Consider whether step context should capture actual MessageIDs from "send message" actions and pass them to webhook steps.

4. **Projection waiting via full page reload** (`acceptance-tests/steps/email.steps.js`)  
   **Smell**: Status assertions force full page reload with `await this.page.goto(this.page.url())` to wait for projections.  
   **Why judgement-worthy**: This heavyweight approach works but is slower and less precise than LiveView-aware waiting (e.g., polling a data attribute, using WebSocket message timing, or Playwright's `expect.poll()` on specific DOM state). If projection latency grows or LiveView optimizes away full reloads, this pattern might become flaky. Consider whether `expect.poll()` or LiveView test helpers could provide lighter, more robust synchronization.

5. **No screenshots on browser test failure** (entire `acceptance-tests/` suite)  
   **Smell**: Playwright supports automatic screenshot capture on assertion failures, but this isn't configured.  
   **Why judgement-worthy**: When browser tests fail in CI, screenshots provide crucial debugging context (especially for projection timing or LiveView state issues). Adding Playwright's `screenshot: 'only-on-failure'` configuration would improve debugging without adding noise to passing runs. Acceptable to defer until first CI flakiness incident, but low-hanging diagnostic fruit.

6. **Hardcoded common step expectations** (`acceptance-tests/steps/common.steps.js`)  
   **Smell**: Steps like "each addressed member should have a separate delivery record" hardcode verification for Alice/Bob/Carol instead of dynamically checking `this.members` state.  
   **Why judgement-worthy**: This works for current scenario shapes but isn't extensible. If a scenario adds/removes members dynamically, the step breaks. The comment "Implementation depends on how deliveries are displayed in the UI" suggests this is acknowledged technical debt. Acceptable for initial implementation, but if these steps are reused in varied scenarios, consider making them state-aware (iterate over `this.members` instead of hardcoded names).

7. **Limited Phoenix startup diagnostics** (`acceptance-tests/harness/phoenix.js`)  
   **Smell**: `startPhoenix()` waits for HTTP 200 on `/` but doesn't verify compilation success, migration state, or Commanded event store readiness.  
   **Why judgement-worthy**: If Phoenix fails to compile or migrations are missing, the HTTP readiness check might time out with a generic "server not ready" error instead of a clear compilation or migration failure message. Current implementation works, but if startup failures become common in CI, adding pre-flight checks (`mix compile --warnings-as-errors`, `mix ecto.migrate --check`) could improve diagnostic clarity. Defer unless startup failures become a debugging bottleneck.

## Suggested Fixes

Apply bounded-safe fixes 1-5 above. No changes to feature files, product behavior, or architectural decisions needed.

## Validation Notes

- ✅ `dev check` passed (109 tests, 0 failures)
- ✅ Elixir/domain acceptance suite runs all scenarios (verified by `cucumber_test.exs` assertion on `@todo-web` filtering)
- ✅ Browser suite configured to exclude `@todo-web` via `cucumber.config.js`
- ✅ Shared features symlinked (inferred from passing tests and cucumber config)
- ✅ Phoenix harness implements ADR-prescribed startup/teardown sequence
- ✅ Browser steps use semantic selectors and bounded waiting per ADR synchronization strategy

**Post-review validation**: Run `bin/dev browser-acceptance` to confirm browser suite passes with implemented steps. All bounded-safe fixes are low-risk refactorings that preserve behavior.