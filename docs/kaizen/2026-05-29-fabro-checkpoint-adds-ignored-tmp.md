# Problem: Fabro checkpoint tried to add ignored .fabro/tmp

Date: 2026-05-29

Selected iteration: 003 Messaging skeleton
Plan path: docs/iterations/003-messaging-skeleton/plan.md

Fabro run ID: 01KSTJ2JBVHHYA7GS0XARNG18F
Web UI: https://fabro.home.wynne.family/runs/01KSTJ2JBVHHYA7GS0XARNG18F

Failed stage/status: checkpoint after `preflight_sandbox`; run status FAILED.

Exact failure text:

```text
Failure: git checkpoint commit failed for node 'preflight_sandbox': git add failed (exit 1)
```

Checkpoint event stderr:

```text
The following paths are ignored by one of your .gitignore files:
.fabro/tmp
hint: Use -f if you really want to add them.
hint: Disable this message with "git config set advice.addIgnoredFile false"
```

Commands used to inspect the run:

```bash
fabro events 01KSTJ2JBVHHYA7GS0XARNG18F
fabro logs 01KSTJ2JBVHHYA7GS0XARNG18F
```

Observations:

- The `read_plan` and `preflight_sandbox` stages both succeeded.
- The workflow failed after the successful preflight stage, while Fabro was creating a checkpoint commit.
- The failure came from Fabro's checkpoint machinery invoking `git add` on `.fabro/tmp`, which is intentionally ignored/excluded by the workflow configuration.
- No implementation task had started yet, and the run failed before any product code, tests, or acceptance criteria were attempted.
- This is therefore a workflow/tooling failure rather than an ordinary implementation failure.

Retry/resume command:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/003-messaging-skeleton/plan.md
```

Do not retry until the checkpoint/ignored-file interaction is resolved, otherwise the run is expected to fail deterministically at the same stage.

## Resolution

Date: 2026-05-31

Root cause: Fabro checkpointing attempted to stage ignored `.fabro/tmp` content, causing checkpoint failure.

Fix applied:

- `75c1d67`: changed the workflow so Fabro tmp content is not ignored in a way that breaks checkpoint staging.

Validation:

- Historical delivery evidence: the checkpoint tmp fix is present on `main`.

Remaining follow-up:

- None for this note.
