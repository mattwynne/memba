You are independently reviewing an iteration plan before implementation.

Use your file-reading tools to read the complete plan file directly from `{{ inputs.plan_path }}`. Do not rely on summarized prior-stage context for the plan text. Do not edit files.

If you cannot read the plan file completely with tools, report NOT READY with a blocking workflow-evidence gap rather than treating unseen sections as absent from the plan.

Before assessing readiness, perform an architecture-conformance review against relevant accepted ADRs:

1. Read `docs/adr/README.md` completely and use it as the status/index source.
2. Identify architecture areas touched by the plan, including aggregate identity, command routing, consistency boundaries, persistence ownership, projections/read models, framework choices, integrations, and runtime/deployment boundaries.
3. Read every accepted ADR cited by the plan and every accepted ADR from the index that is relevant to those areas. Read each relevant ADR completely, including its Decision and Consequences; do not infer conformance from its title or general intent.
4. Compare each binding decision with exact plan evidence. A validated plan cannot silently supersede an accepted ADR.
5. Report NOT READY when the plan contradicts an accepted ADR, asks implementation to reinterpret one, or omits a required supersession decision. Such a conflict requires Matt to revise the plan, retain the ADR, or write/accept a successor ADR; it is not an obvious editorial repair.
6. If no accepted ADR is relevant, record that conclusion and the architecture areas/index entries checked. Do not write only `None`.

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

Return exactly one JSON object for workflow routing, with no Markdown outside the object and no code fence. The workflow's routing schema may discard free-form prose, so the JSON context fields themselves must carry the substantive review evidence.

Use these keys exactly so synthesis can fail closed:

- `gemini_review_decision`: `READY` or `NOT READY`
- `gemini_review_confidence`: `High`, `Medium`, or `Low`
- `gemini_review_blocking_gap_count`: integer count of blocking gaps
- `gemini_review_blocking_gaps`: concise semicolon-separated blocking gaps, or `None`
- `gemini_review_required_edits`: concise semicolon-separated required edits, or `None`
- `gemini_review_adrs_considered`: semicolon-separated accepted ADR file paths/numbers read, or a reasoned `None relevant — ...` statement naming the architecture areas checked
- `gemini_review_adr_conflict_count`: integer count of accepted-ADR conflicts
- `gemini_review_adr_conflicts`: concise semicolon-separated conflicts naming the ADR and contradictory plan decision, or `None`
- `gemini_review_adr_evidence`: concise semicolon-separated comparisons of each relevant ADR's binding decision with exact plan evidence
- `gemini_review_report`: a substantive Markdown report encoded as a JSON string, containing Decision, Confidence, Blocking gaps, Non-blocking improvements, Smallest viable iteration, Required plan edits, Validation plan, and an ADR conformance table with ADR, binding decision, plan evidence, and result

A READY result requires `gemini_review_adr_conflict_count` to be `0` and non-empty, repository-specific ADR evidence. Do not return a bare READY vote.

Example shape:

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":1,"gemini_review_blocking_gaps":"ADR 0011 requires membership_id routing, but the plan routes membership writes by club_id","gemini_review_required_edits":"Ask Matt to retain ADR 0011 or accept a successor ADR before revising the plan","gemini_review_adrs_considered":"docs/adr/0011-use-caller-generated-uuid-aggregate-identities.md","gemini_review_adr_conflict_count":1,"gemini_review_adr_conflicts":"ADR 0011 membership identity and projection preflight contradict the proposed Club route and aggregate-state duplicate check","gemini_review_adr_evidence":"ADR 0011: membership_id route and projection preflight; plan: club_id route and no projection preflight; result: CONFLICT","gemini_review_report":"## Decision\nNOT READY\n\n## ADR conformance\nADR 0011 conflicts with the proposed routing and duplicate check."}}
