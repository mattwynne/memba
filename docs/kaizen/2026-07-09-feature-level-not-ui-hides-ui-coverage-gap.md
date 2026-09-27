# Problem: Feature-level `@not-ui` hides UI coverage gaps

Date: 2026-07-09

## Context

While inspecting the follower toggle and reply-notification behaviour on the member message show page, we traced the acceptance examples in `acceptance-tests/features/club_message_replies.feature` and their step definitions.

Matt supplied the observation:

> weve somehow ended up with "@not-ui" tagged scenarios meaning we have no way of knowing this that behaviour is working through the ui

The workflow step was acceptance-coverage review: checking where the product proves that following or not following a conversation changes whether a member receives reply emails, and whether the in-app follower toggle is exercised through the browser.

## Expected standard

`@not-ui` should have a strong reason. Normally it should be temporary during development, or reserved for scenarios that are intentionally not meaningful through browser automation.

Browser-meaningful user behaviour should either run in the browser acceptance suite or carry an explicit temporary `@todo-ui` gap so the missing UI coverage is visible and removable.

## What happened

`acceptance-tests/features/club_message_replies.feature` is tagged at feature level:

```gherkin
@not-ui @iteration-039
Feature: Club message replies (conversations)
```

Because the browser Cucumber config excludes `@not-ui`, all 19 scenarios in that feature are excluded from browser Cucumber, including scenarios that now appear UI-meaningful:

- replying on a message conversation page;
- seeing replies and their order;
- following and stopping following a conversation;
- proving follower/non-follower email delivery from a browser-driven journey;
- club home conversation rows and reply counts;
- conversation page content/alignment checks.

A search found no other `@not-ui` tags under `acceptance-tests/features/`; this is a single broad feature-level exclusion.

There is browser support code for follow/unfollow in `acceptance-tests/features/support/member_message.js`, but it is not exercised because of the feature-level tag. That helper also appears stale: it clicks `#member-conversation-follow-button` / `#member-conversation-unfollow-button`, while the current UI uses `#member-conversation-follow-toggle`.

The current proof is split across domain Cucumber and LiveView tests: domain scenarios prove delivery rules, and LiveView tests prove the compact toggle changes follow state. The shared acceptance feature does not currently prove the end-to-end UI path.

## Impact

The acceptance suite can give a false sense that follower behaviour is covered while browser Cucumber has no signal for the member-visible journey. A future UI regression in the follower toggle, reply page, or browser-level delivery path could be missed unless a lower-level LiveView test happens to catch it.

The feature-level tag also hides which scenarios are genuinely non-UI versus merely not yet wired through browser automation.

## What allowed it to happen

The tag is too coarse. A single feature-level `@not-ui` converted a mixed feature into a completely non-browser feature, and later iterations added UI-meaningful scenarios under that umbrella without forcing a tag decision per scenario/rule.

The browser acceptance configuration correctly excludes `@not-ui`, but there is no guardrail warning when a feature-level `@not-ui` covers many scenarios or when browser step support exists but is unreachable because the feature is excluded.

## Observations

- `rg -n "@not-ui" acceptance-tests/features -S` found only `acceptance-tests/features/club_message_replies.feature:1`.
- The file currently contains 19 scenarios, all inheriting `@not-ui`.
- `acceptance-tests/README.md` defines `@not-ui` as intentionally not meaningful through browser automation.
- The follower delivery scenarios are implemented in the Elixir/domain Cucumber step definitions using `Messaging.follow_conversation_as_current_member/2` and `Messaging.unfollow_conversation_as_current_member/2`.
- The browser helper code in `acceptance-tests/features/support/member_message.js` still references button IDs that current LiveView tests assert do not exist.
- Current UI toggle coverage exists in `web/test/memba_web/live/member_message_live/show_reply_test.exs` and `show_test.exs`, not in browser Cucumber.

## Why this matters

Shared acceptance features are meant to be executable product contracts. If a broad tag silently removes browser execution for scenarios that describe member-visible behaviour, the contract becomes ambiguous: it documents desired behaviour, but not which user path has been proven.

## Open questions

- Which scenarios in `club_message_replies.feature` are truly not meaningful through browser automation?
- Which scenarios should run in browser Cucumber once the stale follow-toggle helper is updated?
- Should tag policy allow feature-level `@not-ui`, or require scenario/rule-level tags with justification?

## Possible prevention ideas

- Add a lint/check that flags feature-level `@not-ui`, or requires an allowlisted justification.
- Prefer `@todo-ui` for temporary browser gaps so they are visibly pending rather than declared non-UI.
- Add a check that reports the number of scenarios hidden by each broad tag.
- Include tag review in iteration planning/review when adding scenarios under an already-tagged feature.

## Resolution

Date: 2026-09-27

Root cause: the inherited feature-level `@not-ui` tag excluded every conversation rule example from browser Cucumber, while the suite had no selection check to reveal a browser-meaningful example trapped under that tag. The follower helper's old selectors had also drifted from the UI. Removing the tag alone did not prove the toggle in a real browser: the later [ADR 0026](../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md) deliberately moved browser selection to a few `@journey` scenarios, leaving conversation rules at the domain layer.

Fix applied:

- Earlier commit `ac757aa27` removed the broad tag and updated the follower helper to the actual checkbox. Commit `553062bed` adopted separate browser journeys; `acceptance-tests/test/cucumber_config.test.js` now rejects the legacy `@not-ui` tag anywhere in feature files, including inherited feature tags.
- `acceptance-tests/features/journeys/member_messaging.feature`: added Carol's initial not-following state, follow action/state, and unfollow action/state around Bob's existing website reply. This exercises the connected toggle within an existing coherent browser journey without duplicating all domain delivery-rule permutations.
- `acceptance-tests/features/step_definitions/member_message_steps.js`: bound those steps to the existing browser follow/unfollow helpers and projected-state assertions; no product behaviour changed.
- `acceptance-tests/test/cucumber_config.test.js`: kept the journey-file structure check compatible with a deliberately deferred `@journey @todo` file; `@todo` journeys must remain unselected, not fail the file-layout check. The original legacy-tag rejection remains in place.
- `docs/kaizen/README.md`: closed this observation.

Validation:

- Before binding the new steps, `npx cucumber-js --dry-run features/journeys/member_messaging.feature` reported four undefined steps; after binding, it reported none.
- `dev acceptance features/journeys/member_messaging.feature` — passed with 27/27 steps, including the initial-state assertion.
- `node --test test/cucumber_config.test.js` — passed 13/13 after the existing journey-file test was corrected. The broader `npm run test:config` run before that correction failed on the already-deferred future journey and four server-command tests invoked outside their required test environment; it is not a full-gate result.
- `dev check` on a separate worktree with only this candidate staged — passed (1,572 ExUnit tests, 0 failures; 5 browser journeys, 88 steps passed). Repeated after recording this result below so the staged candidate and validated diff match exactly.

Expected versus observed: the focused journey should exercise the real toggle in both directions, and the legacy-tag check should prevent this broad exclusion from returning. The focused browser run passes with the explicit initial-state assertion, and the full gate passes; recurrence prevention beyond these checks has not yet been demonstrated over future runs. Browser email-delivery permutations remain deliberately at the domain layer; this change proves the toggle, not provider delivery through a browser. Review point: the next normal acceptance-suite run on the committed change; further recurrence monitoring belongs in normal acceptance review rather than a separate experiment.
