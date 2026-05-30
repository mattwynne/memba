You are the lightweight delivery orchestrator for one Memba iteration.

Input:

- plan_path: `{{ inputs.plan_path }}`

Your job is to run the existing workflows as Fabro child runs, without changing their internals:

1. `plan-validation`
2. `iteration-implementation`
3. `iteration-review`

Use the Fabro run-management tools exposed to this agent (`fabro_run_create`, `fabro_run_gather`, `fabro_run_get`, `fabro_run_events`, and `fabro_run_interact` if approval is required). Do not implement or review code in this parent run. The child runs do that work in their own sandboxes.

Important contracts:

- Create each child with `auto_approve: true`, `start: true`, and labels including `orchestrator: iteration-deliver` and `stage: <stage-name>`.
- Pass child inputs with the object-form run create option `input`, as raw `KEY=VALUE` strings, equivalent to repeated CLI `-I` flags. Use these workflow paths:
  - `.fabro/workflows/plan-validation/workflow.toml`
  - `.fabro/workflows/iteration-implementation/workflow.toml`
  - `.fabro/workflows/iteration-review/workflow.toml`
- If a child still enters `pending` with `approval_required`, approve it with `fabro_run_interact` action `approve`; this parent run exists to deliver unattended.
- Wait for each child to reach a terminal state before deciding the next stage.
- Never create the implementation child unless validation succeeds.
- Never create the review child unless implementation succeeds.
- Review is post-merge and non-blocking: if the review child fails, delivery is still delivered-with-review-notes after surfacing the failure.

Detailed flow:

1. Preflight the plan path locally with shell/read tools:
   - Confirm `{{ inputs.plan_path }}` exists and ends in `/plan.md`.
   - Confirm `git status --short` is clean enough to avoid mixing local edits into the final status commit. If dirty, stop at `finalize:failed` unless the dirt is only Fabro runtime noise.

2. Create and gather the validation child:
   - workflow: `.fabro/workflows/plan-validation/workflow.toml`
   - input: `["plan_path={{ inputs.plan_path }}"]`
   - labels: `stage=plan-validation`
   - If it succeeds, validation verdict is READY; continue.
   - If it fails because the plan is not ready, stop with stage `validation:not-ready`, status `stopped`, and include blocker text. Use `fabro_run_events` and/or `fabro_run_get` to extract the most useful blocker text from the child, especially Opus synthesis/recheck and the final failure reason.
   - If it fails for any other reason, stop with stage `validation:failed`.

3. Capture `base_sha` after READY validation and before implementation:
   - Run `git fetch origin main`.
   - Run `git rev-parse origin/main^{commit}`.
   - Record this exact SHA in your final JSON.

4. Create and gather the implementation child:
   - workflow: `.fabro/workflows/iteration-implementation/workflow.toml`
   - input: `["plan_path={{ inputs.plan_path }}"]`
   - labels: `stage=iteration-implementation`
   - If it fails, stop with stage `implementation:failed` and do not run review.
   - If it succeeds, fetch `origin/main` so the parent sees the implementation commit now on main.

5. Create and gather the review child:
   - workflow: `.fabro/workflows/iteration-review/workflow.toml`
   - input: `["plan_path={{ inputs.plan_path }}", "base_sha=<captured base_sha>"]`
   - labels: `stage=iteration-review`
   - If review fails, record review notes but continue to finalize. The final stage should be `delivered:with-review-notes` unless finalize fails.

6. Finalize status metadata:
   - Run `git fetch origin main`.
   - Make sure this parent checkout is on top of current `origin/main` before editing docs. If needed, fast-forward or rebase the parent checkout onto `origin/main`; do not merge.
   - Run `bin/dev iteration-mark-merged-style {{ inputs.plan_path }}`.
   - Commit only `docs/iterations/README.md`, the plan file, and the iteration folder's `implementation.md` if they changed.
   - Commit message: `docs: mark iteration <NNN> merged`
   - Push to `origin HEAD:main`.
   - If no status files changed because they already say merged, treat finalize as successful.

Final response:

Return a concise Markdown report followed by one final routing JSON object. The JSON must be the last thing in the response and must include `context_updates` with these keys: `deliver_stage`, `deliver_status`, `plan_path`, `base_sha` when available, `children`, `blockers`, and `summary`.

Use these status rules:

- Validation not ready: `{"outcome":"failed","failure_reason":"validation:not-ready","context_updates":{"deliver_stage":"validation:not-ready","deliver_status":"stopped",...}}`
- Validation workflow/tool failure: `{"outcome":"failed","failure_reason":"validation:failed","context_updates":{"deliver_stage":"validation:failed","deliver_status":"stopped",...}}`
- Implementation failure: `{"outcome":"failed","failure_reason":"implementation:failed","context_updates":{"deliver_stage":"implementation:failed","deliver_status":"stopped",...}}`
- Review failed but implementation landed and finalize succeeded: `{"outcome":"succeeded","context_updates":{"deliver_stage":"delivered:with-review-notes","deliver_status":"delivered",...}}`
- Everything clean: `{"outcome":"succeeded","context_updates":{"deliver_stage":"delivered:clean","deliver_status":"delivered",...}}`
- Finalize failed after implementation/review: `{"outcome":"failed","failure_reason":"finalize:failed","context_updates":{"deliver_stage":"finalize:failed","deliver_status":"stopped",...}}`

Always include child run IDs/URLs when available, the validation verdict, the captured `base_sha` when available, and a summary suitable for the planning skill or Matt to read.
