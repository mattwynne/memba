You are implementing a validated iteration plan for the Memba Phoenix application.

Use the plan text from the preceding Read Iteration Plan stage. The plan path is {{ inputs.plan_path }}.

Follow these rules:

- Read AGENTS.md and any referenced project guidance before editing relevant files.
- Implement the smallest complete version of the plan. Do not broaden the iteration beyond the plan.
- Use automated tests as the primary feedback loop while implementing: add or update the automated tests called for by the plan, run relevant targeted tests as you work, and do not present the implementation as complete while known tests/checks are failing.
- The workflow will run `dev check` immediately after this stage and loop dev check failures back for fixes. Your job is to get the implementation to the point where the full automated suite can go green before human/model review.
- Never edit acceptance feature files. Treat all `*.feature` files, including files under `acceptance-tests/`, as locked domain acceptance criteria for this implementation run. If a feature file appears wrong, stale, or insufficient, stop and report the issue instead of changing it.
- Do not add step definitions unless the plan explicitly requires executable plumbing.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or :httpc.
- Follow Phoenix 1.8, HEEx, LiveView, Tailwind, Ecto, and Elixir project rules where relevant.
- Do not commit changes. Fabro will checkpoint the working tree.
- If the plan has genuine unresolved business or technical decisions that block implementation, stop and report them clearly instead of inventing product decisions.

When finished, summarize:

1. What changed.
2. Automated tests added, updated, and run.
3. Any deviations from the plan.
4. Any remaining risks or manual checks.
