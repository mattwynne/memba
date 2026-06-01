You are independently reviewing an iteration plan before implementation.

Use the complete plan text from the preceding chunked `Read Plan ...` stages. Each chunk has `PLAN_CHUNK_LINES` markers. Do not assume any missing details. Be strict, practical, and specific.

If a chunk says the plan exceeds the chunk limit, or if required chunks are missing/omitted from context, report NOT READY with a blocking workflow-evidence gap rather than treating unseen sections as absent from the plan.

Review the plan against these readiness questions:

1. Goal clarity
   - Is the goal clearly articulated?
   - Does it state the user/business outcome, not just tasks?
   - Is the intended beneficiary or actor clear?

2. Scope focus
   - Is the scope focused on one coherent outcome?
   - Could the iteration be any smaller while still useful?
   - Are non-goals and boundaries clear?

3. Acceptance criteria, BDD scenario decision, and business decisions
   - Are acceptance criteria concrete, clear, complete, and objectively testable?
   - Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?
   - Does the plan classify the iteration as behaviour-facing or technical/engineering?
   - For behaviour-facing or domain-policy changes, does the plan include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenarios that will express the rules, or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples?
   - Are any business, product, policy, copy, workflow, or domain decisions still unresolved?

4. Implementation plan and technical decisions
   - Are implementation steps clear, ordered, and specific?
   - Are likely files, modules, migrations, tests, interfaces, and integration points named where useful?
   - Are data model, API, UI, workflow, integration, and background-job changes clear enough?
   - Are any technical decisions still unresolved?

5. Expected capability and validation
   - What should we be able to do after this iteration that we cannot do now?
   - How will we prove success?
   - Is there a clear stop condition?

Return a Markdown report with:

- Decision: READY or NOT READY
- Confidence: High, Medium, or Low
- Blocking gaps: numbered list
- Non-blocking improvements: numbered list
- Smallest viable iteration: your recommended smallest useful slice
- Required plan edits: concrete edits the author should make
- Validation plan: how to prove the iteration succeeded

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response and must not be wrapped in a Markdown code fence.

Use these keys exactly so the synthesis stage can fail closed if reviewer findings are not visible in context:

- `codex_review_decision`: `READY` or `NOT READY`
- `codex_review_confidence`: `High`, `Medium`, or `Low`
- `codex_review_blocking_gap_count`: integer count of blocking gaps
- `codex_review_blocking_gaps`: concise semicolon-separated blocking gaps, or `None`
- `codex_review_required_edits`: concise semicolon-separated required edits, or `None`

Examples:

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Ordering is not decided; Acceptance criteria omit visible table columns","codex_review_required_edits":"State ordering; Define table columns and row identity"}}
