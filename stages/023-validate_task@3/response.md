### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree has no ordinary code diff; recent checkpoint `c536ca2` contains the task evidence.
  - `c536ca2` changes exactly one ordinary todo line from unchecked to checked:
    - `003 Add or update Membership query tests covering: members with no roles, members with multiple roles sorted alphabetically, and removed members not appearing even when they had roles.`
  - Parent state of `c536ca2` had tasks `001` and `002` checked and `003` as the first unchecked task.

- Implementation artifacts found:
  - `web/test/memba/membership/query_test.exs` was updated.
  - Added `RemoveMember` command alias.
  - Added test: `"excludes removed members even when they had assigned roles"`.
  - Added `remove_member/1` helper using `App.dispatch(%RemoveMember{}, consistency: :strong)`.
  - Existing query tests in the same describe block already cover multiple role names sorted alphabetically and no-role members returning `roles: []`, so task `003` coverage is now complete.

- Tests run/results found:
  - Reran focused validation:
    - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs`
    - Result: `18 tests, 0 failures`.

- ADR/plan conformance notes:
  - Work stays within implementation plan task `003`.
  - No acceptance feature files were edited.
  - No todo scope was deleted, weakened, reordered, or silently deferred.
  - No relevant ADR conflicts found from the plan/context; changes use existing Membership commands/projections and test style.

{"context_updates":{"task_valid":true,"task_retry_available":false}}