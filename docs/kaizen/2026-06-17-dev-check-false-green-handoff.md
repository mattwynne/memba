# Problem: Handoff claimed `dev check` passed while current main fails in ExUnit

Date: 2026-06-17

## Context

Matt asked about an agent handoff that said:

- `./bin/dev check passed on the exact pushed state (REAL_EXIT=0, 82/82 acceptance scenarios)`
- a flaky browser acceptance run was retried until green
- `798 tests, 20 failures` was pre-existing member-message/Cucumber work that `dev check` does not gate on and was identical on main

The repository was on `main` at `bdd6af70f84f3cd7542db48bdc7a33420157af9a`, matching `origin/main`.

## Expected standard

`./bin/dev check` is the required local quality gate after code, config, dependency, migration, acceptance-test, or app-behaviour changes. A delivery handoff should report its result accurately, including whether the command failed before browser acceptance.

## What happened

A fresh local run of the quick gate on the current pushed state failed:

```text
./bin/dev check --quick
...
798 tests, 20 failures
```

The failures include:

- 8 ordinary ExUnit failures in member message/detail, page-controller, and layout tests.
- 12 `Memba.DomainCucumberAcceptanceTest` failures due to missing domain step definitions such as:
  - `When Alice signs in with their email address`
  - `When Pat signs in with "pat@memba.io"`
  - `When Robin accepts the invitation as "Robin Example"`
  - `When Pat converts Robin's West Coast Paddlers request with slug "wcp"`

This means the statement that `dev check` passed on the exact pushed state is not consistent with the current repository and command behaviour. It also means the statement that `dev check` does not gate on the `798 tests, 20 failures` line appears wrong for this state: `dev check --quick` fails during `mix precommit`, before browser acceptance can run.

## Impact

High quality risk. A false-green handoff on the required gate can let a failing `main` branch proceed, shift debugging cost to the next person, and train agents to trust summaries over reproducible command evidence.

## What allowed it to happen

The workflow/handoff did not leave enough verifiable evidence to reconcile the claimed `REAL_EXIT=0` with the actual command, commit SHA, environment, and full output. The acceptance result count (`82/82 acceptance scenarios`) may have been conflated with the whole `dev check` result, or a rerun may have validated only the browser acceptance stage after an earlier ExUnit failure.

## Observations

- `git status --short --branch` showed `## main...origin/main` with no local changes before and after the investigation.
- `git rev-parse HEAD` and `git rev-parse origin/main` both returned `bdd6af70f84f3cd7542db48bdc7a33420157af9a`.
- `bin/dev check` runs `precommit` before browser acceptance.
- `precommit` runs `mix precommit`, whose alias includes `test`.
- The failing `./bin/dev check --quick` run reproduced the `798 tests, 20 failures` line locally.

## Why this matters

If agents can report `dev check` as green while the pushed state fails the ExUnit/precommit stage, the delivery pipeline loses its most important local quality signal. Future reviewers may waste time investigating downstream acceptance flakes while the branch is already red at an earlier gate.

## Open questions

- What exact command produced the claimed `REAL_EXIT=0`?
- Was the command run from the repository root, a sandbox clone, or a stale branch/commit?
- Did the runner capture and publish the full stdout/stderr and commit SHA for the final gate?
- Should the handoff template require pasting the final command, exit code, commit SHA, and final summary lines verbatim?

## Possible prevention ideas

- Make the delivery workflow capture a machine-readable validation artifact with command, working directory, commit SHA, exit code, and tail of output.
- Require `./bin/dev check` final-gate evidence to include both ExUnit/precommit and browser acceptance summaries.
- Fail publication or handoff if the claimed validation commit differs from `origin/main` after push.

## Mitigation applied

- Added a concise guardrail to `AGENTS.md`: report `dev check` as passing only after it ran on the exact committed/pushed state or a clean worktree with the same diff staged for commit.
