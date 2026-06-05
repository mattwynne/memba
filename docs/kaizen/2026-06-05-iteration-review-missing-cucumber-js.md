# Problem: IterationReview dev check cannot find cucumber-js

Date: 2026-06-05

## Context

The `IterationReview` Fabro workflow was reviewing a completed plan-conforming implementation for code polish, ADR conformance, and code-health signals.

- Workflow: `IterationReview` (30 nodes, 41 edges)
- Workflow definition: `.fabro/workflows/iteration-review/workflow.fabro`
- Run: `01KTCS5B6M5RQS0SV9XA5QZ31M`
- Web UI: `https://fabro.home.wynne.family/runs/01KTCS5B6M5RQS0SV9XA5QZ31M`
- Sandbox: docker
- Worktree: `/workspace/memba`
- Base: `review/tmp/main-20260605135623` (`020948b983df`)

## Expected standard

`IterationReview` should be able to run the standard quality gate in its review sandbox. The workflow's `Run Dev Check` node runs:

```sh
PATH="$PWD/bin:$PATH" dev ci
```

`bin/dev ci` starts Postgres, runs `mix precommit`, and then runs the browser acceptance suite via `bin/dev acceptance`. The acceptance step changes into `acceptance-tests/` and runs:

```sh
npm test -- "$@"
```

`acceptance-tests/package.json` currently defines the test script as:

```json
"test": "cucumber-js"
```

The review sandbox preflight should prove that this dependency path is ready before the workflow spends review effort.

## What happened

The workflow passed `Preflight Review Sandbox` after 2m18s, then failed at `Run Dev Check`:

```text
✗ Run Dev Check
Error: sh: line 1: cucumber-js: command not found
```

Fabro then entered `Fix Dev Check Failures`, spent 2m08s and $1.30, and retried `Run Dev Check`. The same infrastructure error repeated at least once:

```text
✗ Run Dev Check
Error: sh: line 1: cucumber-js: command not found
```

The run later managed to repair or work around the missing `cucumber-js` problem by itself and continue, so the abnormality was not permanently blocking. The important signal is that the review workflow first passed preflight, then spent autonomous repair effort on an environment/dependency problem that preflight should ideally have detected earlier.

The run output also reported unrelated workflow-validation warnings for several `goal_gate=true` failure nodes lacking a `retry_target` or `fallback_retry_target`.

## Impact

The review was delayed before it could reach its intended code polish, ADR conformance, or code-health review work. The workflow spent agent time and money fixing what appears to be a missing sandbox dependency rather than an implementation defect. Even though this run eventually recovered by itself, the repeated failure risks wasting review cycles and obscuring the real environment problem in future runs.

## What allowed it to happen

The review sandbox preflight checks for broad tool availability (`node`, `npm`, etc.) and compiles Elixir test dependencies, but it does not appear to verify that JavaScript acceptance dependencies are installed and executable in the sandbox. In particular, it did not catch that the `acceptance-tests` `npm test` script could not resolve `cucumber-js` before `dev ci` ran.

This suggests a weak guardrail between "sandbox has Node/npm" and "the standard project quality gate can actually run." The workflow treated the first failed quality gate as a product-code repair opportunity, even though the failure text pointed to a missing executable in the test environment.

## Observations

- The abnormality appeared in the `Run Dev Check` node, not in `Preflight Review Sandbox`.
- The missing command was `cucumber-js`, invoked through `acceptance-tests/package.json` rather than directly by the workflow.
- `devenv.nix` has an `enterTest` path that runs `(cd acceptance-tests && npm ci)` before `./bin/dev check`, but `bin/dev sandbox-check` does not perform the same acceptance dependency installation or executable check.
- The workflow's repair loop retried after an agent step while the same command-not-found error remained, but the run later managed to fix or work around the problem autonomously.
- The failure is delivery-machinery friction, not evidence that the reviewed product implementation is defective.

## Why this matters

Iteration review is supposed to be a reliable post-merge quality signal. If the review sandbox can pass preflight while lacking acceptance-test executables, future reviews can fail late, spend money on irrelevant repair attempts, and leave completed iterations without review evidence.

## Open questions

- Was `acceptance-tests/node_modules` absent in this sandbox, stale, or present but not on the script resolution path?
- Should Fabro sandbox setup install `acceptance-tests` npm dependencies, or should `bin/dev sandbox-check` fail clearly when they are absent?
- Did the implementation workflow recently pass because it used a different sandbox image, cached dependencies, or setup path?

## Possible prevention ideas

- Extend `bin/dev sandbox-check` or the Fabro review setup to verify `acceptance-tests/node_modules/.bin/cucumber-js` is available before `Run Dev Check`.
- Make the review preflight run a cheap acceptance dependency smoke check, such as `cd acceptance-tests && npm exec -- cucumber-js --version`.
- Teach the workflow to classify `command not found` from quality-gate tooling as an environment/preflight failure rather than sending it through product-code repair.
