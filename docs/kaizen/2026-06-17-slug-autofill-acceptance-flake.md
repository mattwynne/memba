# Problem: Suggested slug autofill acceptance scenario is flaky

Date: 2026-06-17

## Context

Matt shared an agent handoff reporting that one `./bin/dev check` run hit a flaky browser acceptance failure:

```text
Staff create a club with the suggested slug
```

The scenario timed out after 5 seconds waiting for slug autofill. The same agent reported rerunning and seeing the unrelated JavaScript flow pass in 3 of 4 runs before pushing.

## Expected standard

Browser acceptance scenarios in `dev check` should provide a reliable signal. If a JavaScript-driven field autofill is expected, the test should either wait on the real browser-observable condition with enough diagnostics or expose a deterministic product/harness failure.

## What happened

One acceptance run timed out waiting for the club slug input to be autofilled. Reruns passed without a reported product-code change.

Existing related evidence: `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md` also records `dev check` failing in browser acceptance at the pre-existing/unrelated `Staff create a club with the suggested slug` scenario, with `#club-slug-input` remaining empty, and says the same scenario could pass on rerun.

## Impact

Moderate quality risk. The required local gate can fail for a timing-sensitive JavaScript path and encourage rerun-until-green behaviour. That makes it harder to distinguish a genuine regression in club creation from a flaky wait or browser event issue.

## What allowed it to happen

The acceptance step appears to depend on a fixed timeout around client-side slug autofill. When the autofill event or browser assertion is delayed or missed, the failure appears as a product acceptance failure rather than a diagnosed harness/timing problem.

## Observations

- Reported timeout: 5 seconds waiting for slug autofill.
- Reported rerun outcome: passed in 3 of 4 runs.
- Earlier kaizen evidence from 2026-06-09: `#club-slug-input` remained empty in the failing run; rerun could pass.
- The scenario name points at a staff club-creation JavaScript flow rather than the member-message/Cucumber ExUnit failures investigated separately.

## Why this matters

A flaky acceptance gate trains agents to retry failures instead of investigating them. Over time that reduces trust in browser acceptance and can hide real regressions in the same flow.

## Open questions

- Is the slug autofill implemented via input/change/debounce events that the acceptance step may not trigger consistently?
- Does the failing run include screenshots, trace/video, console logs, or the current values of the name and slug inputs?
- Should the wait target the actual slug-generation condition instead of a fixed 5-second assertion timeout?

## Possible prevention ideas

- Add diagnostics to the step failure: club name input value, slug input value, focused element, relevant console errors, and screenshot/trace path.
- Replace the fixed wait with condition-based polling tied to the slug input value and any debounce interval.
- Add a targeted browser test for slug autofill so failures can be reproduced without the full acceptance suite.
