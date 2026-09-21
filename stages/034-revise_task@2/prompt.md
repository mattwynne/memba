Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M31RZ6Z1Y1E3W5EK3YKGN8VW


Implement or revise the current delivery-planner packet for `docs/iterations/064-leave-and-remove-group-members/plan.md`.

The planner, not this worker, selected and bounded the task. Read the current packet from the iteration sibling `.delivery/current-worker-packet.json` before editing. Do not choose a different todo line, split tasks, reorder `todo.md`, commission preparation, or run an extra independent review.

## Ownership rules

- Read `AGENTS.md`, the plan, `todo.md`, `.delivery/execution-state.json`, and `.delivery/current-worker-packet.json`.
- Implement exactly the packet's `todo_line`, `outcome`, and `scope` only. Respect `scope_exclusions`.
- On revision, address the packet's latest review gaps for the same pending obligation. Preserve useful candidate work and earlier accepted tasks; do not reset to a clean baseline or start the next task.
- Treat checked todo lines as durable completed work. Do not redo them.
- Inspect `git status --short` before editing. The resume gate should normally guarantee a clean tree; if uncommitted changes are present, stop for human input unless they are clearly this packet's in-progress work and you can safely continue it without overwriting it.
- Never silently overwrite, discard, or duplicate uncommitted or checkpointed candidate work.
- Leave the task unchecked. Only the workflow's `apply_task_verdict` command checks it off after independent acceptance.
- Do not edit `todo.md` except to leave it untouched; task shaping belongs to the delivery planner.
- Do not spawn subagents in this per-task node.
- Do not commission an extra independent review. The workflow's `validate_task` node already provides independent review after Fabro checkpoints your candidate task.
- Do not commit manually. Fabro will checkpoint your changes automatically after this node; independent validation will inspect that checkpoint evidence.

## Local reference docs

- Prefer local project documentation over network lookups. Do not `curl` upstream docs unless the local docs are missing or clearly insufficient.
- Start with `docs/tools/README.md` for library documentation signposts. Relevant local docs include Commanded, EventStore, projections, Cucumber, Ecto, Phoenix and related sources under `docs/tools/` and `web/deps/`.

## Binding rules

- `plan.md` remains the source of truth. The packet is an implementation handoff for approved scope; it cannot authorize weakening the plan or editing locked acceptance features.
- Before editing, read every ADR explicitly referenced by the plan/packet and inspect nearby/current ADRs under `docs/adr/` when relevant.
- Treat accepted ADRs as binding architecture constraints.
- Use test-driven development for behaviour changes.
- Add or update automated tests proving the packet's behaviour/configuration.
- Run the packet's focused validation, or a narrower failing/passing loop plus the specified final focused check when appropriate, and capture commands/results.
- For browser-facing tasks, run targeted browser scenarios or a focused browser harness proving the selected change, alongside relevant component/JS/CSS tests. Browser-facing behaviour, routing, LiveView/UI, and acceptance step changes do not by themselves require the full suite inside this node.
- Do not run `dev check`, `dev check --quick`, `dev ci`, or any other unscoped full-suite command in ordinary implementation tasks. The workflow's deterministic `dev_check` node runs the full `dev ci` gate before publication.
- If the packet explicitly requires a full final-validation task, preserve that requirement: run it and capture a successful exit before requesting acceptance, or return a replan/human-blocked result explaining the missing final exit status.
- Fabro agent shell commands have a documented 600-second maximum, regardless of a longer requested timeout. Do not launch detached/background full-suite retries to evade a timeout.
- In the Fabro sandbox, prefer `PATH="$PWD/bin:$PATH" dev test ...` for focused Elixir tests and `PATH="$PWD/bin:$PATH" dev acceptance ...` for focused browser scenarios. Do not use direct `bin/mix test ...` in the sandbox unless you have a specific, safe reason.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. If a feature file appears wrong, stale, or insufficient without explicit permission, return `human_blocked`.
- Add acceptance step definitions only where the approved plan explicitly requires executable plumbing for shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or `:httpc`.
- Follow relevant project guidance for Phoenix, LiveView, HEEx, Tailwind, Ecto, Elixir, Mix, and tests.

## Required worker result artifact

Before finishing, write `.delivery/latest-worker-result.json` in the iteration directory with JSON object:

- `schema_version`: `1`.
- `packet_id`, `task_id`, `todo_line`: exactly from `current-worker-packet.json`.
- `result`: one of `ready_for_review`, `replan`, or `human_blocked`.
- `changed_paths`: changed code/config/test/doc paths for this packet.
- `validation`: final commands, exit statuses, and concise evidence. For `ready_for_review`, include only successful final validation runs (every `exit_status` must be `0`); summarize superseded failing TDD/diagnostic runs in `notes` instead of adding them to this array.
- `notes`: one non-empty concise string summarizing useful discoveries, reusable helpers and non-obvious constraints; do not write an array.
- `unresolved`: unresolved facts or candidate work still needing validation.
- For `replan`, include `replan_request` with the specific blocker, partial work, completed checks, remaining validation and why the packet is too broad/missing a prerequisite.
- For `human_blocked`, state the business/acceptance-contract decision needed.

Use `ready_for_review` only when the packet is implemented and focused validation has passed. Use `replan` for missing preparation, excessive scope, or a technical prerequisite outside the packet. Use `human_blocked` for acceptance-contract ambiguity, unsafe work, repeated non-transient lack of progress, or required decisions.

When finished, summarize the packet id, result, changes, validation and any replan/human-blocked evidence. The deterministic workflow reads the JSON artifact for routing.