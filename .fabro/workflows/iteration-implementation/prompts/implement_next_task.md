Implement the next unchecked iteration task from `todo.md`.

Plan path: `{{ inputs.plan_path }}`.
Todo path is derived from the plan path by replacing `/plan.md` with `/todo.md`.

## Ownership rules

- Read the plan and `todo.md` before editing.
- Pick the first unchecked Markdown task line in `todo.md` (`- [ ] ...`). That task is yours from selection through check-off.
- Treat earlier checked todo lines as durable completed work. Do not redo them.
- Inspect recent Fabro checkpoint commits with `git log --oneline --decorate -20` and use their subjects/bodies/diffs as context for what previous runs already completed.
- Read existing implementation notes, reviews, and recovery handoffs for the selected task before repeating repository-wide research. A committed failed checkpoint is candidate work, not a completed task: inspect and continue or correct it without treating its unchecked todo as untouched work.
- Inspect `git status --short` before editing. The resume gate should normally guarantee a clean tree; if uncommitted changes are present, stop for human input unless they are clearly the selected task's in-progress work and you can safely continue it to completion without overwriting it.
- Never silently overwrite, discard, or duplicate uncommitted work for an unchecked task.
- Implement exactly the selected task only. Do not opportunistically implement later tasks unless the selected task cannot be completed without splitting/reordering the todo list first.
- When the implementation and focused validation are complete, check off the same task line you implemented by changing that one line from `- [ ]` to `- [x]`.
- Immediately before editing `todo.md` for that check-off, read the exact active todo path with the agent read tool, then patch only the selected line. Shell `cat`, earlier workflow/script output, and prior reads of other paths do not satisfy Fabro's active-agent read guard.
- Do not check off any other ordinary todo line.
- Do not spawn subagents in this per-task node. Keep task research, implementation, and focused validation under one bounded owner so child-agent waits cannot consume the node's fixed deadline.
- Do not commission an extra independent review. The workflow's next `validate_task` node already provides independent review after Fabro checkpoints your completed task.
- Do not commit manually. Fabro will checkpoint your changes automatically after this node; independent validation will inspect that checkpoint evidence.


## Local reference docs

- Prefer local project documentation over network lookups. Do not `curl` upstream docs unless the local docs are missing or clearly insufficient.
- Start with `docs/tools/README.md` for library documentation signposts. Relevant local docs include:
  - `docs/tools/commanded/README.md` for Commanded.
  - `docs/tools/commanded-eventstore-adapter/README.md` for the EventStore adapter.
  - `docs/tools/eventstore/README.md` for EventStore.
  - `docs/tools/commanded-ecto-projections/README.md` for projections.
  - `docs/tools/cucumber/README.md` for Elixir Cucumber.
  - `docs/tools/ecto/README.md` and `docs/tools/ecto-sql/README.md` for Ecto.
  - `docs/tools/phoenix/README.md` and related Phoenix docs for web framework work.
- If you need examples, search the local `web/deps/` source tree and `docs/tools/` before using the network.

## Binding rules

- `plan.md` remains the source of truth. `todo.md` is derived execution state.
- You may split the selected task into smaller unchecked tasks, add required technical subtasks, or reorder pending tasks only to satisfy the approved plan.
- If the selected task is too large, split it in `todo.md`, leave the parent/current task unchecked or replace it with smaller unchecked tasks, then implement and check off only the first newly available slice.
- You may not delete, weaken, or silently defer plan-required work.
- Before editing, read every ADR explicitly referenced by the plan and inspect nearby/current ADRs under `docs/adr/` when relevant.
- Treat accepted ADRs as binding architecture constraints.
- Use test-driven development for behaviour changes.
- Add or update automated tests proving the selected task's behaviour/configuration.
- Run focused validation appropriate to the selected task and capture the commands/results in your response.
- For per-task validation, prefer the smallest checks that prove the selected task: relevant focused tests plus formatting for touched files when practical.
- For browser-facing tasks, run targeted browser scenarios or a focused browser harness proving the selected change, alongside relevant component/JS/CSS tests. Browser-facing behaviour, routing, LiveView/UI, and acceptance step changes do not by themselves require the full suite inside this node.
- Use `PATH="$PWD/bin:$PATH" dev check --quick` only when broad non-browser validation is useful; it does not replace focused browser evidence for browser-facing changes.
- Do not run full `dev check` or `dev ci` in ordinary implementation tasks. The workflow's deterministic `dev_check` node runs the full `dev ci` gate before publication; task completion is not a claim that the full suite passed.
- If the selected task explicitly requires the full final validation, preserve that requirement: run it and capture a successful exit before checking it off, or leave it unchecked and report the blocker. Do not silently delete, defer, or claim completion of an explicit validation task. Such legacy plan tasks still duplicate the workflow gate until a separate gate-ownership handoff is implemented.
- Fabro agent shell commands have a documented 600-second maximum, regardless of a longer requested timeout. This prompt node also has a 2,400-second total budget. Do not start a long gate without enough remaining time to finish and report it; if the known gate duration exceeds either budget, stop with the selected task, validation still required, and checkpoint/recovery evidence instead of starting a doomed run.
- Do not launch a detached/background full-suite retry to evade a tool timeout. A timeout is not a failed assertion or a passing gate: preserve the last command, captured results, missing final exit status, and any possibly surviving child processes in the handoff. Diagnose the specific failure before retrying broad validation.
- In the Fabro sandbox, avoid wrapping focused commands in `devenv shell -- ...` unless there is a specific reason. The sandbox image and project wrappers are already prepared for the project; prefer `PATH="$PWD/bin:$PATH" dev test ...` for focused Elixir tests and `PATH="$PWD/bin:$PATH" dev ...` for broader project checks so command execution stays consistent with the workflow environment. Do not use direct `bin/mix test ...` for focused tests in a Fabro sandbox because stale baked `PGHOST`/`PGPORT` values can point it at the wrong Postgres socket.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. If the plan permits a feature edit, make only that explicit edit and preserve/validate the coverage promised by the plan. If a feature file appears wrong, stale, or insufficient without explicit permission, stop and report the issue.
- Add acceptance step definitions only where the plan explicitly requires executable plumbing for shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or `:httpc`.
- Follow relevant project guidance for Phoenix, LiveView, HEEx, Tailwind, Ecto, Elixir, Mix, and tests.
- If you hit a real blocker, stop and report it clearly without checking off the task.

When finished, summarize:

1. Selected todo line and task text.
2. Code/config/test/doc changes made for this task only.
3. Focused validation commands run and results.
4. The exact todo check-off you made.
5. Any todo splits/additions/reordering and why they still satisfy the plan.
6. ADR conformance evidence for this task.
