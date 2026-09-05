# Problem: recovered iteration workflow launched from the wrong checkout

Date: 2026-09-05

## Observation

Iteration 057 had a complete, validated recovery artifact on `origin/work/057-finish` at `cf0c8775aa7e7ddda5476d0f75efa6e6cc1156af`. A final verification watcher was instructed to clone that branch into `/tmp/memba-057-final-watch`, verify its commit, and launch the implementation workflow there.

The watcher created and verified the disposable clone, but its later `fabro run` command executed from the original repository checkout instead. Fabro run `01M1R5TVZZATZ0DBN13A9YZP34` therefore recorded:

```text
source_directory: /Users/matt/git/mattwynne/memba
source HEAD: 19a51a338fa1e414391d184d264ab4a5cce73b7c
```

rather than the intended source:

```text
source_directory: /tmp/memba-057-final-watch
source HEAD: cf0c8775aa7e7ddda5476d0f75efa6e6cc1156af
```

The incorrect run regenerated and began implementing old tasks. The mistake was detected after the one-hour wait timed out, and the run was cancelled at `implement_next_task@3` before publication. `origin/main` remained at `19a51a338`; the authoritative recovery branch remained intact. The run and its remote checkpoint/meta branches were preserved.

## Impact

- About one hour and $72.63 of model spend were wasted.
- Publication and review of an already complete iteration were delayed.
- Natural-language instructions and an earlier checkout assertion did not remain coupled to the later launch command.

## Root cause

The workflow accepted whichever repository happened to be the launch process's current directory. Although the operator verified the intended clone first, no machine-checkable source-commit expectation crossed the launch boundary. Fabro therefore had no way to distinguish the correct recovered branch from an older clean `main` checkout containing the same workflow and plan path.

## Resolution

Date: 2026-09-05

Fix applied:

- Added `expected_source_head` to the iteration-implementation workflow inputs.
- Added a first `Verify Source Checkout` node that compares the sandbox's exact 40-character `HEAD` with the expected source commit and fails before reading the plan or spending implementation tokens when they differ or the expectation is omitted.
- Updated `bin/dev fabro deliver` to pass the exact reserved implementation base SHA automatically.
- Added focused verifier and workflow-routing regressions for matching, mismatching, and omitted source commits.
- Recovery launches must now pass `-I expected_source_head=<exact SHA>` in the same `fabro run` command; checking a clone in an earlier command is no longer considered sufficient.

Validation:

- `bash .fabro/workflows/iteration-implementation/scripts/test_verify_source_head.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_workflow_routing.sh` — passed, including the fail-before-plan route.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml --no-upgrade-check` — `Validation: OK`; only the existing intentional publish goal-gate warning remains.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev check` — 1,129 tests with 0 failures; 122 browser scenarios and 877 steps passed.
- Independent Claude review — approved with no blockers.

Remaining follow-up:

- Use the guarded command to retry iteration 057 from the authoritative recovery commit and confirm the real Fabro sandbox reports the expected source HEAD before continuing.
