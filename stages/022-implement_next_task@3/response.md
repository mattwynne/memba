Implemented the first split of task 021 and left it unchecked for independent review.

Selected task:

`- [ ] 021 Complete targeted Club concurrency, identity, replay, departure/rejoin, slug-length and LiveView validation test coverage.`

Changes made:

- Added authoritative concurrency coverage in [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:314):
  - concurrent same-name attempts produce exactly one Board group;
  - only the successful creator becomes a member;
  - concurrent distinct names sharing a slug stem receive `board` and `board-2`;
  - allocated addresses survive aggregate shutdown and replay unchanged.
- Added multi-digit suffix-length coverage in [custom_group_slug_test.exs](/workspace/memba/web/test/memba/membership/custom_group_slug_test.exs:24), proving a maximum-length stem is shortened correctly for `-10`.
- Added successive server-side typing coverage in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_group_live/new_test.exs:204), proving each LiveView validation retains the latest input, updates the preview, and creates no group.
- Existing focused tests already cover actor identity/authorization, historical replay compatibility, departure/rejoin follow clearing, rapid re-add ordering, fallback slugs, duplicate correction, stale previews, and submit-time revalidation.

Validation:

- Focused new-test runs:
  - Membership and slug tests: 20 tests, 0 failures.
  - LiveView tests: 10 tests, 0 failures.
- Complete task-021 matrix:
  - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/create_custom_group_dispatch_test.exs test/memba/membership/custom_group_slug_test.exs test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs test/memba/membership/clear_removed_group_member_follows_policy_test.exs test/memba_web/live/member_group_live/new_test.exs`
  - 95 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,348 tests, 0 failures.
- Formatting completed successfully.
- `git diff --check` is clean.

Todo split:

The original final task covered two large independently reviewable test layers. A dry-run found 32 expanded iteration-062 browser scenarios with 267 steps, including 251 undefined steps. I split it in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:23) without removing any requirement:

- Task 021 owns the focused aggregate, replay, lifecycle, slug, and LiveView validation matrix.
- Task 022 retains all tagged domain/browser scenarios, real-browser typing/caret evidence, and the mandatory full browser-inclusive `dev check`.

Exact selected line, still unchecked:

`- [ ] 021 Complete targeted Club concurrency, identity, replay, departure/rejoin, slug-length and LiveView validation test coverage.`

ADR conformance:

- ADRs 0002 and 0009: concurrency and replay are tested through the existing Commanded Club aggregate and projections.
- ADR 0011: tests continue using caller-generated typed group IDs.
- ADRs 0013 and 0015: LiveView behaviour is exercised through form events and stable DOM IDs.
- ADR 0024: authoritative name and slug races remain inside the Club consistency boundary.
- ADRs 0021 and 0022: focused integration tests use established strong-consistency and projection synchronization rather than timing sleeps.
- ADRs 0003 and 0010: shared Cucumber activation remains intact and explicitly assigned to task 022; no acceptance scenario was changed or hidden.