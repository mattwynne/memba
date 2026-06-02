### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Live working tree is clean; `/tmp/fabro-pre-validate-snapshot.md` also shows no working-tree diff at snapshot time.
  - Recent commits show `4c669fa fabro(...): implement_next_task (succeeded)` followed by `9fbd6de ... pre_validate_snapshot`.
  - `git diff 4c669fa^ 4c669fa -- docs/iterations/015-club-slugs/todo.md` shows exactly one ordinary task changed from unchecked to checked:
    - `008 Do not support replay of old slug-less ClubCreated events...`
  - `git show 4c669fa^:docs/iterations/015-club-slugs/todo.md` confirms task 008 was the first unchecked task when implementation started.

- Implementation artifacts found:
  - `ClubCreated` now enforces `:slug` as a required event struct key.
  - `CreateClub` docs now describe slug as required.
  - `Memba.Membership.Club.execute/2` validates the command slug before emitting `ClubCreated`.
  - `Memba.Membership.Projectors.Club` validates projected event slugs and rejects missing/invalid slug values instead of backfilling or replaying old slug-less events.
  - Tests were added/updated to cover missing slug rejection and slug-less event replay rejection.
  - Direct command/support call sites that omitted slugs were updated to supply valid slugs.
  - No `.feature` files were changed.

- Tests run/results found:
  - I ran `PATH="$PWD/bin:$PATH" dev check`.
  - Result: passed — `272 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Work directly satisfies implementation plan task 008 and preserves remaining tasks 009–015.
  - Keeps `club_id` as the aggregate identity; slug remains a required public attribute.
  - Uses existing Membership and Commanded Ecto projector paths.
  - Does not add Messaging coupling or custom projection infrastructure.
  - Todo changes did not delete, weaken, split, or silently defer plan-required work.

{"context_updates":{"task_valid":true,"task_retry_available":false}}