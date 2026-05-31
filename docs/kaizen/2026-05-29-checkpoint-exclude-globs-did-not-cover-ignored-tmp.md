# Problem: checkpoint exclude globs did not prevent ignored .fabro/tmp add

Date: 2026-05-29

Selected iteration: 003 Messaging skeleton
Plan path: docs/iterations/003-messaging-skeleton/plan.md

Fabro run ID: 01KSTK8FDB2W2PEXAZHYQNP02D
Web UI: https://fabro.home.wynne.family/runs/01KSTK8FDB2W2PEXAZHYQNP02D

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
fabro events 01KSTK8FDB2W2PEXAZHYQNP02D
fabro logs 01KSTK8FDB2W2PEXAZHYQNP02D
fabro inspect 01KSTK8FDB2W2PEXAZHYQNP02D
```

Observations:

- The run used base SHA `be940c3294129eb6d1733d3cd4ea4952225ac0fa`, which included commit `be940c3` changing `[run.checkpoint].exclude_globs` from `[".fabro/tmp/**"]` to `[".fabro/tmp", ".fabro/tmp/**"]`.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` passed before the run.
- The `read_plan` and `preflight_sandbox` stages both succeeded.
- The failure occurred while Fabro was creating the checkpoint after `preflight_sandbox`, before any product implementation work started.
- The repeated failure shows the checkpoint exclusion metadata alone did not prevent Fabro checkpoint machinery from attempting `git add .fabro/tmp` when that path was ignored by `.git/info/exclude`.
- The preflight script wrote `.fabro/tmp/` into `.git/info/exclude`, so the workflow itself created the ignored-path condition that Fabro's checkpoint add could not tolerate.
- This is a workflow/tooling failure rather than an implementation failure: no product code was attempted, and the failure is in checkpoint/ignored-file interaction.

Retry/resume command:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/003-messaging-skeleton/plan.md
```

Do not retry with a workflow that writes `.fabro/tmp/` into `.git/info/exclude` before Fabro checkpoints; it is expected to fail deterministically at the same stage.

## Resolution

Date: 2026-05-31

Root cause: Checkpoint exclude globs did not prevent Git from rejecting ignored `.fabro/tmp` paths during staging.

Fix applied:

- `75c1d67`: avoided the ignored-tmp checkpoint failure by changing how Fabro tmp paths are handled.

Validation:

- Historical delivery evidence: the ignored-tmp checkpoint fix is present on `main`.

Remaining follow-up:

- None for this note.
