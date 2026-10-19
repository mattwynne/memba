Selected “Alice’s older edit requires confirmation of the newer name” as the first scenario.

It establishes the reusable `RenamePerson`/`PersonRenamed` path and the plan’s core aggregate-level compare-and-confirm semantics before expanding into cross-club historical reads or browser UI. The validation-only scenario would not require a successful rename/event path.

Prepared state:

- Exactly one domain scenario is tagged `@wip`.
- The other two iteration-068 domain scenarios remain `@todo`.
- The browser journey and all iteration-069 scenarios are unchanged.
- Handoff context is recorded in [.fabro/tmp/bdd-plan/progress.md](/workspace/memba/.fabro/tmp/bdd-plan/progress.md).
- The exact plan path is recorded in [.fabro/tmp/bdd-plan/plan-path](/workspace/memba/.fabro/tmp/bdd-plan/plan-path).
- No previous `.fabro/tmp/bdd/` evidence existed to archive.
- No application tests were run.

{"preferred_next_label":"implement"}