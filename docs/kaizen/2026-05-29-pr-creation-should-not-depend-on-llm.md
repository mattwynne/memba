# Kaizen: PR creation should not depend on an LLM

Date: 2026-05-29

## Context

While rehearsing recovery for failed implementation run `01KSR7ATV5Q77HJ5A1SDT3V3A2`, we recovered the old task commits, resumed from branch `recover/01KSR7-task008`, and completed the iteration with run `01KSRNSNJBPV741JKWHH9211XM`.

The implementation workflow itself succeeded:

- Fabro cloned the recovery branch with managed clone enabled.
- The run saw the existing `todo.md` with tasks 001–008 already checked.
- It resumed at task 009 rather than reimplementing earlier tasks.
- The final `todo.md` had tasks 001–009 checked.
- `dev ci` passed with `30 tests, 0 failures`.

However, the completed work was not delivered to `main` and no pull request was created.

## What happened

The run branch exists:

```text
fabro/run/01KSRNSNJBPV741JKWHH9211XM
```

But no PR exists for either:

```text
recover/01KSR7-task008
fabro/run/01KSRNSNJBPV741JKWHH9211XM
```

`origin/main` also does not contain the recovered implementation commits.

The Fabro event log shows why PR creation failed:

```text
pull_request.failed
PR creation failed: LLM generation failed: Invalid request to anthropic: Your credit balance is too low to access the Anthropic API.
```

So the implementation finished, validation passed, and the run branch was pushed, but delivery stopped because the PR creation path depended on an Anthropic-backed LLM call.

## Why this is a problem

Opening a pull request is operational plumbing. It should be deterministic and reliable after a successful run.

Using an LLM to polish a PR title or body is helpful, but it must not be on the critical path. A model outage, billing issue, missing API key, or rate limit should not prevent a validated branch from being proposed for merge.

The current behavior creates a confusing state:

- the workflow reports success;
- the implementation appears complete;
- the run branch is pushed;
- but there is no PR and nothing is merged;
- the operator has to inspect events to discover that PR creation failed for an unrelated provider/billing reason.

This is especially painful after a recovery run, where the whole goal is to finish and deliver already-expensive work without further manual archaeology.

## Desired behavior

PR creation should have a deterministic fallback, or be deterministic by default.

At minimum Fabro can create a PR using data it already has:

- run id;
- workflow name;
- plan path and input values;
- base branch;
- head/run branch;
- final run status;
- validation commands and outcomes;
- final commit SHA;
- changed files or commit list;
- link to the Fabro run.

A generated PR body could be plain and mechanical, for example:

```text
Run: 01KSRNSNJBPV741JKWHH9211XM
Workflow: iteration-implementation
Plan: docs/iterations/001-event-sourced-foundation/plan.md
Head: fabro/run/01KSRNSNJBPV741JKWHH9211XM
Base: main
Status: succeeded
Validation: dev ci passed
```

An LLM-generated summary may be added later as a non-blocking comment or optional enhancement. It should not decide whether the PR exists.

## Suggested fix

Change Fabro's PR creation path to:

1. Push the run branch.
2. Create a PR with a deterministic title/body template.
3. If an LLM summary is configured and available, append or update the PR body/comment with the richer summary.
4. If the LLM call fails, record a warning but keep the PR open.

The failure mode should be:

```text
PR created with deterministic body; LLM summary skipped because provider unavailable.
```

not:

```text
PR creation failed because provider unavailable.
```

## Acceptance criteria

- A successful run with `run.pull_request.enabled = true` opens a PR even when the configured/default LLM provider is unavailable.
- The PR body contains deterministic run metadata sufficient for review.
- LLM summary generation failure is reported as a non-blocking warning.
- The run result clearly reports the PR URL when creation succeeds.
- If PR creation itself fails for a GitHub/API reason, that remains a real PR failure with a clear error.

## Operator workaround

Until Fabro has this fallback, create PRs manually from a clean branch or run branch with `gh pr create` or the GitHub API. Do not rely on Fabro PR automation when provider billing or credentials are unstable.
