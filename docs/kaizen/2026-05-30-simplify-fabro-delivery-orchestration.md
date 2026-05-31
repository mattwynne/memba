# Plan: simplify Fabro delivery orchestration

Date: 2026-05-30

## Context

Recent delivery work exposed avoidable orchestration complexity around iteration workflows:

- `bin/dev iteration-validate-plan` / `bin/dev fabro validate-plan` had routed validation through the `iteration-deliver` parent workflow.
- The parent workflow created `plan-validation` as a child run with auto approval, but the child still entered `approval_required`.
- Fabro rejected worker approval with "Run approval must be performed by a user".
- Running the real workflow directly from the user-controlled CLI with `--auto-approve` succeeded.

This suggests the `.fabro/workflows/iteration-deliver/` parent workflow is currently the wrong orchestration layer. It exists mainly to start other Fabro workflows as child runs, but that worker-created child-run boundary is exactly where the approval problem appears.

The goal is to simplify around one user-controlled shell entry point for delivery.

## Desired shape

Keep only these public iteration workflow commands:

```bash
bin/dev fabro validate-plan <plan_path>
bin/dev fabro deliver <plan_path>
bin/dev fabro review <branch> <plan_path> [base_ref_or_base_sha]
```

Roles:

- `validate-plan`: run standalone plan validation directly with user CLI approval.
- `deliver`: orchestrate the full delivery sequence from `bin/dev`, not from a Fabro parent workflow.
- `review`: keep only as a manual recovery/debug escape hatch for rerunning review against a known branch/base.

Remove public status-only commands:

```bash
bin/dev fabro mark-merged
bin/dev fabro mark-merged-style
```

Status finalization should be owned by the delivery/review flow, not exposed as separate operator commands.

## Proposed delivery flow

`bin/dev fabro deliver <plan_path>` should run the real workflows in sequence from the user-controlled CLI:

1. Validate the plan:
   ```bash
   fabro run .fabro/workflows/plan-validation/workflow.toml \
     -I plan_path=<plan_path> \
     --auto-approve
   ```
2. Check the implementation WIP slot is clear.
3. Mark the iteration `implementing`, update `docs/iterations/README.md`, commit/push status metadata.
4. Capture `base_sha` from current `origin/main` after the status commit.
5. Run implementation directly:
   ```bash
   fabro run .fabro/workflows/iteration-implementation/workflow.toml \
     -I plan_path=<plan_path> \
     --auto-approve
   ```
6. Watch the implementation run in the foreground, or use `fabro attach`/`fabro wait` if the command detaches.
7. Fetch `origin/main` and run review directly:
   ```bash
   fabro run .fabro/workflows/iteration-review/workflow.toml \
     -I plan_path=<plan_path> \
     -I base_sha=<base_sha> \
     --auto-approve
   ```
8. Let the review workflow finalize the iteration status as `merged` after it has either published green polish or confirmed there are no review changes.

## Move merged finalization into review

The review workflow is already the last delivery stage:

- implementation has landed on `main` before review starts;
- review inspects the diff from `base_sha` to `HEAD`;
- review may publish a green polish commit;
- after review succeeds, delivery is complete.

Therefore `.fabro/workflows/iteration-review/` should mark the iteration `merged` as its final successful step.

Expected behaviour:

- implementation succeeds + review succeeds/no-op/polish succeeds → review marks the iteration `merged`.
- implementation succeeds + review fails → leave the iteration in its current in-progress state and report the review rerun command.

This removes the need for both `mark-merged` and `mark-merged-style` as public commands.

## Remove the broken parent workflow

Delete or archive:

```text
.fabro/workflows/iteration-deliver/
```

Rationale:

- It currently exists to create child Fabro runs from a worker context.
- Worker-created children can still require approval.
- Fabro rejects worker approval for that gate.
- The simpler user CLI path works and is easier to understand.

If a parent orchestrator becomes useful later, reintroduce it only after the child-run approval contract is reliable.

## Simplify skills and slash commands

Iteration skills should not wrap non-interactive workflow commands. That creates stale orchestration instructions and another layer to maintain.

Keep:

- `iteration-planning` skill, because planning is interactive and conversational.

Change `iteration-planning` so it:

1. interviews Matt;
2. writes the iteration plan and acceptance artefacts;
3. commits/pushes planning artifacts;
4. ends with instructions to run:
   ```bash
   bin/dev fabro deliver <plan_path>
   ```

Optionally, if Matt explicitly asks for early validation, the planning skill may run:

```bash
bin/dev fabro validate-plan <plan_path>
```

Remove or retire:

- `iteration-deliver` skill;
- `iteration-implementation` skill;
- `iteration-review` skill.

Keep unrelated thinking/process skills such as BDD and kaizen skills; they remain useful because they guide interactive work rather than wrapping a deterministic command.

Slash commands currently appear fine; no iteration-specific slash-command cleanup is needed unless new commands are discovered.

## Documentation updates

Update references in:

- `.fabro/workflows/README.md`
- `.pi/skills/iteration-planning/SKILL.md`
- any remaining project docs or workflow error text that mention:
  - `iteration-deliver`
  - `bin/dev iteration-*`
  - `bin/dev fabro start`
  - `bin/dev fabro mark-merged`
  - `bin/dev fabro mark-merged-style`

Canonical commands should become:

```bash
bin/dev fabro validate-plan <plan_path>
bin/dev fabro deliver <plan_path>
bin/dev fabro review <branch> <plan_path> [base_ref_or_base_sha]
```

## Validation plan

After implementation:

- `bash -n bin/dev`
- `bin/dev fabro --help`
- `fabro validate .fabro/workflows/plan-validation/workflow.toml`
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml`
- `fabro validate .fabro/workflows/iteration-review/workflow.toml`
- `dev check`

If practical, run a dry/safe smoke of argument validation for:

```bash
bin/dev fabro deliver
bin/dev fabro review
```

## Open questions

- Should `bin/dev fabro deliver` run each workflow in the foreground, or should it use `--detach` plus `fabro attach`/`fabro wait` for better run ID handling?
- Should a failed review leave status as `implementing`, or should delivery introduce a distinct status such as `review-failed`?
- Should `bin/dev fabro review` also finalize `merged` when run manually, or only when invoked by `deliver`?
