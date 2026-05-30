# Plan: salvage iteration 005 app slice

Date: 2026-05-30

## Purpose

Recover the useful application-side work from failed Fabro run `01KSVP69ES02ATWQ9S3E9MGJAD` without merging the failed run branch wholesale.

## Inputs

- Failed run branch: `origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD`
- Original plan: `docs/iterations/005-browser-acceptance-harness/plan.md`
- Problem note: `docs/kaizen/2026-05-30-iteration-implementation-reset-cycle-limit.md`

## Approach

1. Create a fresh branch from current `origin/main`.
2. Inspect `origin/main..origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD` and select only app-slice changes.
3. Bring over:
   - public Membership APIs needed by the LiveViews;
   - public Messaging APIs needed by the webhook/status flow, after reviewing consistency semantics;
   - Postmark webhook controller and tests;
   - `/clubs`, `/clubs/:club_id`, and `/messages/:message_id` LiveViews and routes;
   - PhoenixTest/controller/router tests for the app surface;
   - narrow test support needed by those tests.
4. Exclude:
   - JS Cucumber step-definition rewrites;
   - Playwright/browser server lifecycle changes;
   - broad acceptance-test config/package changes unless independently justified;
   - stale workflow, skill, planning, or kaizen changes from the failed run branch.
5. Re-scope iteration 005 plan/index to describe the smaller delivered app substrate and explicitly defer browser Cucumber automation.
6. Run `dev check`.
7. If green, commit the salvaged 005 slice and prepare review handoff metadata.

## Consistency question

Do not blindly keep strong-consistency defaults added during the failed run. Inspect why they were introduced. Prefer test/harness synchronization on recorded events or projected read-model state unless strong consistency is an intentional production API contract.

## Done when

- The salvaged branch contains only the app-surface slice.
- `dev check` passes.
- Iteration 005 plan/index describe the actual delivered scope.
- Handoff metadata is ready for review.
