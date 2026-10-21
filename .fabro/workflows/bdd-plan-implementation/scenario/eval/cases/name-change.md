# Alice's older edit requires confirmation of the newer name

## Fixed starting point

- Historical application base: `5645fb62d50892b763f419f4b08e5d22b9a0e4bd` (before name editing was implemented).
- Approved plan/scenario source: `c5402f0bd8fc99587c8b220b51643ecd650377eb`.
- Seed plan: `docs/iterations/068-member-name-editing/plan.md`, with its linked ADRs/designs. The workflow is responsible for this one WIP scenario, not the entire iteration.
- [Fixture patch](name-change.patch): adds only the exact approved stale-name rule/example, changing its temporary `@todo` to `@wip`. Existing pending name/photo examples stay untouched.
- Freeze a workflow/test-tooling commit for each batch. Record both that commit and the resulting prepared commit in every result.

## Prepare once per version

In a new throwaway worktree at the historical base, bring only these files from the frozen workflow/test-tooling commit:

```text
.fabro/workflows/bdd-plan-implementation/scenario/
bin/dev
web/test/support/domain_cucumber_runner.ex
web/test/features/domain_cucumber_wip_test.exs
web/test/features/domain_cucumber_runner_test.exs
web/test/features/dev_wip_command_test.exs
acceptance-tests/README.md
```

Restore `docs/iterations/068-member-name-editing/` from the approved-plan commit. These are context documents, not the completed application. Apply `name-change.patch`. Review the complete setup diff: it must contain only workflow/test tooling, plan context and the new tagged example—no completed rename command, event, step definitions or product implementation. Check that the plan's relevant local links resolve.

Commit that prepared source and make its throwaway branch available through the normal remote. All three runs start from this **same commit**, not a previous run branch. Launch from that branch:

```sh
fabro run .fabro/workflows/bdd-plan-implementation/scenario/workflow.toml \
  --environment memba-dev \
  --server https://fabro.home.wynne.family \
  -I plan=docs/iterations/068-member-name-editing/plan.md \
  --no-upgrade-check --json --detach
```

Record the acknowledgement before doing anything else. Monitor, download native logs/artifacts and inspect the resulting Git checkpoint. Do not copy completed implementation from main or manually repair a run. Do not push replay product code to main.

## Expected observations

Initially `dev test:wip` selects exactly this example and fails at the undefined first Given. This is legitimate missing implementation, not infrastructure failure.

The final behaviour is:

1. Alice starts an edit based on `Alice Smith`.
2. A subsequent real name change stores `Alice Jones`.
3. Her old edit requesting `Alice Brown` is rejected without changing the stored name.
4. Explicit confirmation based on `Alice Jones` stores `Alice Brown`.

Verify actual Membership preparation/dispatch, aggregate rules, events, projection and query—not a test-side name store. Preserve self-only authority, normalized current-name comparison and historical event replay as described in the plan. Supporting unit tests should cover relevant edge cases; equivalent correct Elixir is acceptable, byte-for-byte reproduction of an old patch is not the goal.

After the example passes, `dev test:wip` still exits nonzero and asks to remove the tag. The navigator removes only `@wip`; the ordinary focused command and final full check must execute the real scenario normally. The workflow finishes when the full check passes. It does not run refactoring or review.

Apply the [shared checklist](../README.md). This exercise does not prove refactoring, review, every recovery path, novel feature discovery or whole-iteration delivery.
