### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - `/tmp/fabro-pre-validate-snapshot.md` shows clean validation-time working tree at implement checkpoint `355e106`.
  - Live `git status --short` and `git diff` are clean; current HEAD is a later `pre_validate_snapshot` checkpoint, with `355e106` as the recent `implement_next_task` checkpoint.
  - `git diff 355e106^ 355e106 -- docs/iterations/015-club-slugs/todo.md` shows exactly one ordinary task changed:
    - `009 Add Membership.get_club_by_slug/1...` from unchecked to checked.
  - `git show 355e106^:docs/iterations/015-club-slugs/todo.md` confirms task 009 was the first unchecked task when the implementation started.

- Implementation artifacts found:
  - `web/lib/memba/membership.ex` adds `Membership.get_club_by_slug/1`, querying the Club projection by slug and returning `nil` for invalid inputs.
  - `web/lib/memba/membership/slug.ex` adds `Slug.normalize_for_lookup/1`, trimming and downcasing only, then validating without kebab-casing or unsafe rewriting.
  - `web/test/memba/membership/query_test.exs` adds coverage for exact slug lookup, safe casing/whitespace normalization, unknown slugs, invalid slugs, and non-string input.
  - `web/test/memba/membership/slug_test.exs` adds focused normalization tests.
  - No `*.feature` files were changed in the implement commit.

- Tests run/results found:
  - I ran `PATH="$PWD/bin:$PATH" dev check`.
  - Result: passed — `277 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Satisfies implementation plan task 009 directly.
  - Preserves `club_id` as aggregate identity; slug is only a public lookup key.
  - Keeps the query in the Membership public API, consistent with bounded-context guidance.
  - Uses the existing Ecto projection/read model; no custom projection infrastructure added.
  - No plan-required work was deleted, weakened, reordered, or silently deferred.

{"context_updates":{"task_valid":true,"task_retry_available":false}}