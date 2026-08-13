# Problem: Button refactor reached main incomplete, while a browser scenario flickered during recovery

Date: 2026-08-13

## Context

Before delivering iteration 054 (`docs/iterations/054-member-name-editing/plan.md`), the required `PATH="$PWD/bin:$PATH" dev check` quality-gate step was run on `main`.

The immediate failure was traced to `aab58490a` (`Unify button components`, 2026-07-16). That commit changed the shared `<.button>` API and related context-menu markup across 21 files. It reached `main` although its existing interface and tests were not kept coherent. The repair was published as `50f04dc4a` (`Fix unified button component regressions`).

While verifying the repair, one full browser-acceptance run also failed at the first scenario of `member_message_deliverability.feature`, then the same message-send path passed on a later run without a product-code change.

## Expected standard

The shared-component refactor workflow must preserve each explicitly supported component contract, or deliberately update every consumer and its tests together. In particular, `<.button>` callers must retain additive `class`, supported `size`, HTML attribute, and selector behaviour where those are part of the current application/test contract.

The `dev check` gate must pass on the exact artifact before it is treated as delivered. Browser acceptance should give a repeatable result; a projection-wait failure should provide enough evidence to distinguish a real message-send regression from harness timing.

## What happened

The `dev check` run before iteration 054 reported 19 deterministic ExUnit failures, all consistent with an incomplete `aab58490a` refactor:

- `CoreComponents.button/1` no longer declared or merged the caller's `class` attribute.
- Existing `size="sm"` and `size="lg"` arguments were removed from member-facing calls although the component still supported those sizes and tests required their `btn-sm`/`btn-lg` output.
- The club-site sign-out lost its `app-menu__signout` hook class.
- Message-menu CSS and markup were renamed to `context-menu*`, but the associated CSS and LiveView tests still asserted the old public selectors.
- The request-conversion control no longer rendered the expected `type="button"` attribute.

Focused repair tests then passed: 143 tests, 0 failures, followed by the affected My Settings test file: 10 tests, 0 failures.

A later full `dev check` completed its ExUnit stage but browser acceptance failed once in `features/member_message_deliverability.feature`:

```text
Projection timing timeout: timed out waiting for projected browser UI:
member compose success for "Trip planning night".
Locator: #member-message-compose[data-compose-state="sent"]
```

The application log tail included `Member message send failed`, but not the underlying error or the browser state needed to diagnose it. On a later acceptance run, the same `Alice sends a club message` scenario passed without a source change. That later command was itself interrupted by the operator timeout before the full suite completed.

## Impact

The incomplete refactor left `main` red for an extended period and blocked iteration 054 before its implementation could start. It required manual git archaeology, a cross-cutting repair, and repeated long-running quality-gate attempts.

The flickering browser failure further blurred whether the repaired artifact was safe to deliver. Its weak diagnostics and an orphaned acceptance Phoenix process after an externally interrupted run also caused database sessions to remain open and blocked the next acceptance lifecycle from dropping `memba_test`.

## What allowed it to happen

The refactor changed a shared component and many call sites, but the delivery process did not protect the existing component contract as one coherent change. The evidence suggests no final exact-artifact quality-gate result prevented `aab58490a` from reaching `main`, or that any such evidence was not durable enough to detect the mismatch later.

The browser harness's `withProjectionWait` reports only the missing final selector. When the member-message send path fails, the resulting evidence does not include the underlying server error, the rendered compose state, or a categorized distinction between command failure and delayed projection. An externally terminated quality-gate process can also leave the lifecycle's Phoenix server running, which holds test-database connections and turns a later retry into an unrelated database-drop failure.

## Observations

- `aab58490a` modified `web/lib/memba_web/components/core_components.ex`, `web/assets/css/app.css`, and 19 other UI consumers in one commit.
- `50f04dc4a` restored the missing shared-button and selector contracts and updated the stale context-menu assertions.
- The full gate is serialized by `bin/dev`, but external termination can still leave a browser-acceptance child process outside the command's normal cleanup path.
- This is delivery-system friction, not a new iteration-054 product defect.

## Why this matters

Shared UI primitives multiply the blast radius of incomplete refactors. If the required gate cannot reliably prove the artifact or explain browser failures, agents can waste time repairing symptoms, rerunning until green, or starting a new iteration from a red baseline.

## Open questions

- What validation evidence, if any, was recorded when `aab58490a` was accepted onto `main`?
- What was the underlying `Member message send failed` error in the one failed acceptance scenario?
- Why did external timeout leave the acceptance Phoenix process alive despite the lifecycle's cleanup design?

## Possible prevention ideas

- Add a shared-component contract test/matrix that exercises every supported `<.button>` assign combination and representative navigation/button output before accepting a component refactor.
- Require final delivery evidence to name the exact commit SHA and include both ExUnit and browser-acceptance summaries.
- On projection-wait failure, capture the rendered target region, browser console/network errors, and the structured server-side cause; ensure interrupted acceptance runs reap their process group or print a deterministic cleanup command.
