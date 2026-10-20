At Git commit `{{ inputs.commit }}`, choose the next domain scenario to implement.

The commit is your only task input. Discover the repository's plan/status conventions, find its one active implementation plan, and find the agreed `@todo` domain scenarios belonging to that plan. Read the relevant existing code, linked decisions and guidance at that commit. Do not assume the first plan or scenario you find is the next one. A plan waiting to start is not necessarily the active plan.

Choose a useful foundation that establishes successful behaviour before adding constraints and edge cases, taking account of what the code already implements. Prefer scenarios that let later work build on that foundation; do not merely follow file order. Briefly explain the dependency or implementation gap behind your choice.

Work read-only. Use Git reads against the supplied commit (`git show`, `git ls-tree`, `git grep`) so every observation comes from the same snapshot. Do not edit or check out files, implement anything, run application tests, call other agents, or start workflows. Do not use network searches or external information. If there is no unique active plan, report that problem rather than choosing one arbitrarily.

Return only JSON: `{"plan":"relative/path/to/plan.md","feature":"relative/path/to/scenarios.feature","scenario":"exact scenario name","reason":"brief explanation"}`. If the active plan cannot be uniquely identified, return only `{"error":"what you found"}`.
