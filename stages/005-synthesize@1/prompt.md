Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KVG2RXZWPXXJKCXJCXFC4RM6
Pipeline progress: 3 of 10 stages completed

## Stage: gemini_review
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 6.5k in / 1.6k out
- Response:
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking gaps
  > 
  > 1. **Core technical decisions remain unresolved.**  
  >    The plan explicitly leaves open whether the boundary is a synchronous collaborator or a persisted outbox/handoff table, whether provider idempotency is sufficient, and where handoff failure state should live. These choices directly determine implementation shape, migrations, tests, retry semantics, and operational observability.
  > 
  > 2. **The `send_club_message/2` result contract is not concrete enough.**  
  >    Acceptance criteria require a “clear result contract,” but the plan does not define the exact success, partial-failure, and total-failure return shapes. This makes it hard to objectively prove that callers can distinguish committed domain state from provider handoff failure.
  > 
  > 3. **Retry/idempotency semantics are underspecified.**  
  >    The plan requires duplicate/retry safety, but does not define what local state or provider idempotency key is authoritative, when a delivery is considered already handed off, or how retries behave after partial recipient success.
  > 
  > ## Non-blocking improvements
  > 
  > 1. Name the likely test files or test modules to update once the boundary choice is resolved.
  > 2. Clarify whether existing user-facing flash/copy should remain exactly unchanged when handoff fails after commit, or whether internal-only logging/state is sufficient.
  > 3. Add a concise state transition sketch for handoff attempts if a persisted model is chosen.
  > 4. Clarify whether provider failure observability means logs, return values, persisted state, telemetry, admin-facing state, or some combination.
  > 
  > ## Smallest viable iteration
  > 
  > The smallest useful slice is:
  > 
  > - Extract provider delivery into a named `Memba.Messaging.EmailDeliveryHandoff` boundary.
  > - Define a concrete handoff result contract that always preserves the committed `message_id` / delivery IDs.
  > - Add local idempotency/retry protection per `email_delivery_id`, either via an explicit persisted handoff state or a documented decision that provider-level idempotency is sufficient and already available.
  > - Cover success, total failure, partial failure, retry/duplicate safety, and inbound acceptance through ExUnit tests.
  > - Keep user-facing message and delivery-status behaviour unchanged.
  > 
  > ## Required plan edits
  > 
  > 1. Resolve the boundary design: choose either a synchronous structured-result collaborator or a minimal persisted outbox/handoff table.
  > 2. Define the exact `send_club_message/2` return contract for:
  >    - full success,
  >    - provider failure before any recipient is accepted,
  >    - provider failure after one or more recipients are accepted.
  > 3. Define the exact handoff summary shape, including delivery IDs attempted, succeeded, failed, and skipped/already-handed-off if applicable.
  > 4. Specify the idempotency mechanism:
  >    - provider idempotency key,
  >    - local persisted state,
  >    - or both.
  > 5. Specify where handoff failure/retry state is observable.
  > 6. Update acceptance criteria so “observable,” “retryable,” and “duplicate/retry safety” are objectively testable against the chosen design.
  > 
  > ## Validation plan
  > 
  > To prove the iteration succeeded after the plan is revised and implemented:
  > 
  > 1. Run focused ExUnit tests for `Memba.Messaging.send_club_message/2` and the new handoff boundary.
  > 2. Verify successful sends still create message and email-delivery read models and invoke the configured provider.
  > 3. Simulate provider failure before any recipient succeeds and verify:
  >    - the committed message state is not reported as a failed domain send,
  >    - handoff failure is returned or recorded according to the chosen contract.
  > 4. Simulate provider failure after partial success and verify:
  >    - successful delivery IDs are distinguishable from failed ones,
  >    - earlier accepted recipients are not ambiguous.
  > 5. Retry an already-created delivery and verify no second message stream or duplicate `EmailDeliveryCreated` event is produced, and no duplicate provider send occurs according to the chosen idempotency mechanism.
  > 6. Verify inbound club-message acceptance uses the same outbound handoff boundary.
  > 7. Confirm replay/projector paths do not call external providers.
  > 8. Run `dev check`.
  > 
  > {"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Core technical decisions remain unresolved; send_club_message/2 result contract is not concrete; retry/idempotency semantics are underspecified","gemini_review_required_edits":"Choose boundary design; define exact send_club_message/2 and handoff result contracts; specify idempotency mechanism and observable failure/retry state; make retry and observability acceptance criteria objectively testable"}}

## Stage: claude_review
- Status: succeeded
- Handler: agent
- Model: claude-sonnet-4-5
- Tokens: 4.3k in / 2.4k out
- Response:
  > Now I'll evaluate the plan against the readiness criteria and provide a comprehensive review.
  > 
  > ---
  > 
  > # Iteration 038 Plan Review: Email Delivery Handoff Boundary
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > 1. **Handoff result contract unresolved**: Acceptance criteria require "`send_club_message/2` has a clear result contract" but the plan leaves the exact result structure (`:ok` vs. `{:ok, message_id}` vs. `{:ok, %{message_id: ..., handoff: ...}}`) unspecified. Step 4 says "adjust so dispatch and handoff results are not conflated" and mentions "caller should know message_id/dispatch result even when handoff fails," but does not commit to the concrete shape. Without this, the implementation could wander between incompatible options.
  > 
  > 2. **Handoff boundary architectural pattern unresolved**: Open Technical Decisions leaves the core boundary design choice unresolved (synchronous collaborator vs. persisted outbox/handoff table). This is not a minor detail—it fundamentally affects modules, tests, migrations, and retry semantics. The acceptance criteria require "provider handoff failures are observable and testable" and "safe duplicate/retry," but those constraints differ significantly between a synchronous-only collaborator and a persisted outbox. Without choosing, step 2 "define the smallest explicit handoff contract" cannot be concretely implemented.
  > 
  > 3. **Idempotency/duplicate-prevention strategy unresolved**: The plan acknowledges duplicate emails as a risk and lists "duplicate/retry safety" in acceptance criteria, but leaves the implementation strategy open: "if provider adapter lacks idempotency, record enough local state." This is a critical branching point. The plan should state whether Memba will rely on provider-level idempotency keys (and which providers support them), add a local sent-attempt table, or use another mechanism. Without this decision, step 6 cannot be implemented deterministically.
  > 
  > 4. **Handoff-failure representation unresolved**: Open Technical Decisions asks "whether handoff failure should update an existing read model or a new internal operational read model" and notes the desire to avoid "overloading recipient delivery status." The acceptance criteria require "provider handoff failures are observable and testable" but do not specify how. Should failures surface in the `email_deliveries` projection, a new `email_handoff_attempts` table, an in-memory result only, or elsewhere? This decision affects migration planning, query contracts, and observability.
  > 
  > 5. **Partial-recipient-failure semantics undefined**: Acceptance criteria require "provider failure for one recipient cannot cause silent ambiguity about earlier recipients" and tests for "provider failure after at least one recipient has been accepted," but the plan does not specify what should happen in this case. Should the system:
  >    - Return partial success with per-recipient status?
  >    - Retry only failed recipients?
  >    - Fail the entire handoff and retry all recipients later?
  >    - Surface partial success in a new data structure?
  >    
  >    Without this decision, the "structured handoff result" in step 2 cannot be concretely designed.
  > 
  > ## Non-Blocking Improvements
  > 
  > 1. **Inbound acceptance integration could be more specific**: Step 7 says "route inbound accepted club messages through the same handoff contract" but does not name the caller module/function (likely in `Memba.Messaging.InboundEmail` or similar). Adding a line like "adjust `Memba.Messaging.InboundEmail.accept_club_message/2` or similar caller" would make the plan more concrete without changing scope.
  > 
  > 2. **Migration planning omitted**: If the chosen boundary design includes a persisted outbox/handoff table (one of the open options), a migration will be required. The implementation plan could note "if persisted boundary chosen, create migration for handoff state table" in step 5 or as a conditional substep.
  > 
  > 3. **Provider-specific idempotency key support could be researched ahead**: The plan mentions "whether provider adapters already expose enough idempotency key support" but does not propose a pre-implementation research task. Adding a step 0 or 1.5 to "check Postmark/Resend adapter and API docs for idempotency key support" would reduce mid-implementation uncertainty.
  > 
  > ## Smallest Viable Iteration
  > 
  > The current scope is already focused and appropriate. The smallest viable slice within this plan would be:
  > 
  > **Email handoff boundary with synchronous-only, single-transaction retry semantics**:
  > - Extract a `Memba.Messaging.EmailDeliveryHandoff` module that accepts message/delivery data and calls the provider synchronously.
  > - Return `{:ok, message_id, handoff_results}` from `send_club_message/2` where `handoff_results` is a list of `{delivery_id, :sent | {:failed, reason}}`.
  > - Do not add a persisted outbox table; rely on caller retry or accept that mid-send failures are reported but not automatically retried.
  > - Use provider-level idempotency keys if available; otherwise, document that duplicate handoff calls may send duplicate emails (deferring duplicate prevention to a later iteration with persisted state).
  > 
  > However, this smaller slice may not satisfy the acceptance criterion "retrying handoff does not create duplicate EmailDeliveryCreated events" if retries are invoked by replaying the entire `send_club_message/2` call. The plan should clarify whether "retry" means command replay (which would replay events) or handoff-only retry (which requires persisted handoff state or idempotent provider keys).
  > 
  > ## Required Plan Edits
  > 
  > 1. **Resolve handoff result contract**: In the Implementation Plan or a new "Design Decisions" section, specify the exact return shape for `send_club_message/2`. Example: `{:ok, %{message_id: String.t(), handoff: [%{delivery_id: String.t(), status: :sent | {:failed, reason}}]}}` or similar. State what callers should do with handoff failures.
  > 
  > 2. **Choose handoff boundary pattern**: Decide between synchronous collaborator vs. persisted outbox/handoff table and document the choice. If persisted, add migration planning to the implementation steps. If synchronous-only, clarify retry semantics (caller retries entire command vs. no automatic retry).
  > 
  > 3. **Specify idempotency/duplicate-prevention mechanism**: State whether Memba will use provider idempotency keys (and confirm which providers support them), add a local handoff-attempt table, or defer duplicate prevention to a future iteration. Add this decision to the plan and remove the corresponding open question.
  > 
  > 4. **Define handoff-failure representation**: State whether handoff failures will be recorded in a new table, surfaced only in the command result, or reflected in the existing `email_deliveries` projection with a new status/field. Remove the corresponding open question.
  > 
  > 5. **Specify partial-recipient-failure behavior**: Clarify what happens when the provider accepts some recipients but rejects others. Should the handoff return per-recipient results? Should it fail entirely? Should it retry only failed recipients? Add this to the Acceptance Criteria or Implementation Plan.
  > 
  > 6. **Clarify retry semantics vs. event replay**: In Acceptance Criteria or Implementation Plan, distinguish "retrying handoff" (re-attempting provider call for an existing delivery) from "retrying send_club_message" (replaying the domain command). State which kind of retry must not duplicate `EmailDeliveryCreated` events.
  > 
  > ## Validation Plan
  > 
  > The existing validation plan is reasonable but should be augmented based on the resolved decisions:
  > 
  > - Run targeted tests for all acceptance criteria (already stated).
  > - Run `dev check` (already stated).
  > - Manually confirm message and delivery views populate (already stated).
  > - **Add**: Manually or through tests confirm partial-recipient-failure behavior matches the documented design.
  > - **Add**: If persisted handoff state is chosen, manually inspect the handoff table after a simulated failure to confirm retry can be triggered safely.
  > - **Add**: If provider idempotency keys are used, confirm keys are stable across retries and match the delivery ID or another stable identifier.
  > 
  > ---
  > 
  > ## Summary
  > 
  > The iteration has a clear technical goal and appropriate scope. The problem is well-motivated, and the acceptance criteria are comprehensive. However, **four critical design decisions remain unresolved** (result contract, boundary pattern, idempotency strategy, handoff-failure representation, partial-recipient behavior), leaving the implementation plan underspecified. Resolving these decisions and editing the plan accordingly will make it ready for implementation.
  > 
  > Once the blocking gaps are resolved, the plan will be concrete, bounded, and ready for deterministic implementation.
  > 
  > ---
  > 
  > ```json
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":5,"claude_review_blocking_gaps":"Handoff result contract unresolved; Handoff boundary pattern unresolved (sync vs. persisted outbox); Idempotency/duplicate-prevention strategy unresolved; Handoff-failure representation unresolved; Partial-recipient-failure semantics undefined","claude_review_required_edits":"Specify send_club_message/2 result contract; Choose sync collaborator vs. persisted outbox pattern; Decide idempotency mechanism (provider keys vs. local state); Define handoff-failure representation (new table vs. command result only); Specify partial-recipient-failure behavior; Clarify retry semantics vs. event replay"}}
  > ```

## Stage: codex_review
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 10.1k in / 1.7k out
- Response:
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking gaps
  > 
  > 1. **Core handoff architecture is still undecided.**  
  >    The plan explicitly leaves open whether the boundary is only an extracted synchronous collaborator or a persisted outbox/handoff table. That choice affects implementation shape, tests, retry semantics, observability, and stop condition.
  > 
  > 2. **Retry/idempotency mechanism is unresolved.**  
  >    The acceptance criteria require duplicate/retry safety, but the plan does not decide whether safety comes from provider idempotency keys, local persisted handoff state, or another mechanism. This is a blocking technical decision because it is central to the iteration’s stated goal.
  > 
  > 3. **The `send_club_message/2` result contract is not concrete enough.**  
  >    The plan says the function should not conflate domain dispatch with provider handoff and suggests a result “such as” `{:ok, summary}` or `{:error, {:handoff_failed, summary}}`, but it does not define the exact contract callers should rely on. Since this may affect LiveViews, controllers, inbound acceptance, and tests, the plan needs the intended shape before implementation.
  > 
  > 4. **Observable handoff failure state is not specified.**  
  >    The plan requires provider handoff failures to be observable and testable, but leaves open whether that means an existing read model, a new internal operational read model, a handoff table, or structured return-only state. The implementation cannot be reliably validated without knowing where the durable/observable state lives, if any.
  > 
  > ## Non-blocking improvements
  > 
  > 1. Clarify the exact handoff summary fields expected in tests, for example attempted delivery IDs, succeeded delivery IDs, failed delivery IDs, and failure reasons.
  > 
  > 2. Name the most likely test files or test modules to update once the current code is inspected.
  > 
  > 3. Add one sentence explaining whether provider handoff failures should be user-visible in this iteration. The scope implies no UI change, but making that explicit would help prevent accidental product changes.
  > 
  > 4. Clarify whether “provider failure before any recipient is accepted” and “provider failure after at least one recipient has been accepted” refer to provider API acceptance, adapter return values, or local handoff state transitions.
  > 
  > ## Smallest viable iteration
  > 
  > The smallest useful slice is:
  > 
  > - Extract a named `Memba.Messaging` email handoff collaborator.
  > - Define a concrete `send_club_message/2` return contract that always exposes the committed message identity when the domain command succeeds.
  > - Add minimal per-delivery handoff tracking or provider idempotency-key usage sufficient to prevent duplicate sends for already-successful deliveries.
  > - Keep handoff synchronous for now; do not introduce a full background job system.
  > - Add focused ExUnit coverage for full success, total provider failure, partial provider failure, retry/duplicate safety, and inbound accepted club-message handoff.
  > 
  > ## Required plan edits
  > 
  > 1. Decide whether this iteration will implement:
  >    - synchronous collaborator only with provider-level idempotency, or
  >    - synchronous collaborator plus minimal persisted local handoff state, or
  >    - a tiny persisted outbox/handoff table.
  > 
  > 2. Define the exact `Memba.Messaging.send_club_message/2` result contract after this change, including:
  >    - successful domain dispatch and successful handoff,
  >    - successful domain dispatch and failed/partial handoff,
  >    - failed domain dispatch before commit.
  > 
  > 3. Define the retry/idempotency rule in concrete terms, including what uniquely identifies one recipient delivery handoff, likely `email_delivery_id`.
  > 
  > 4. Define where handoff state/failure is observable:
  >    - structured return only,
  >    - existing read model,
  >    - new internal read model/table,
  >    - or another named mechanism.
  > 
  > 5. Update acceptance criteria to match those decisions with concrete expected state changes and return values.
  > 
  > ## Validation plan
  > 
  > Success should be proven by:
  > 
  > 1. Targeted automated tests showing `send_club_message/2` no longer reports the committed message-domain send as failed merely because provider handoff failed afterward.
  > 
  > 2. Tests proving the named handoff collaborator handles:
  >    - all-recipient success,
  >    - provider failure before any accepted recipient,
  >    - provider failure after at least one accepted recipient,
  >    - retry/duplicate safety for an already-created delivery.
  > 
  > 3. Tests proving inbound accepted club messages use the same outbound handoff boundary.
  > 
  > 4. Verification that event/projector replay does not call provider code.
  > 
  > 5. Verification that existing successful browser-composed and inbound-composed message flows still create message and delivery read models and still invoke the configured provider.
  > 
  > 6. `dev check` passing after implementation.
  > 
  > {"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":4,"codex_review_blocking_gaps":"Core handoff architecture undecided; Retry/idempotency mechanism unresolved; send_club_message/2 result contract not concrete; Observable handoff failure state not specified","codex_review_required_edits":"Choose synchronous collaborator vs persisted handoff/outbox design; Define exact send_club_message/2 result contract; Define retry/idempotency rule keyed by delivery; Define where handoff state/failure is observable; Update acceptance criteria with concrete state changes and return values"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 5 |
| claude_review_blocking_gaps | Handoff result contract unresolved; Handoff boundary pattern unresolved (sync vs. persisted outbox); Idempotency/duplicate-prevention strategy unresolved; Handoff-failure representation unresolved; Partial-recipient-failure semantics undefined |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Specify send_club_message/2 result contract; Choose sync collaborator vs. persisted outbox pattern; Decide idempotency mechanism (provider keys vs. local state); Define handoff-failure representation (new table vs. command result only); Specify partial-recipient-failure behavior; Clarify retry semantics vs. event replay |
| codex_review_blocking_gap_count | 4 |
| codex_review_blocking_gaps | Core handoff architecture undecided; Retry/idempotency mechanism unresolved; send_club_message/2 result contract not concrete; Observable handoff failure state not specified |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Choose synchronous collaborator vs persisted handoff/outbox design; Define exact send_club_message/2 result contract; Define retry/idempotency rule keyed by delivery; Define where handoff state/failure is observable; Update acceptance criteria with concrete state changes and return values |
| gemini_review_blocking_gap_count | 3 |
| gemini_review_blocking_gaps | Core technical decisions remain unresolved; send_club_message/2 result contract is not concrete; retry/idempotency semantics are underspecified |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Choose boundary design; define exact send_club_message/2 and handoff result contracts; specify idempotency mechanism and observable failure/retry state; make retry and observability acceptance criteria objectively testable |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the three model reviews and their routing context fields. The reviewer agents read the plan file directly, so do not require plan text to be present in your own summarized context.

The reviewer stages must have exposed both their Markdown reports and these routing context fields. The reviewers run as separate model-review stages so these fields are visible to synthesis:

- Gemini: `gemini_review_decision`, `gemini_review_confidence`, `gemini_review_blocking_gap_count`, `gemini_review_blocking_gaps`, `gemini_review_required_edits`
- Claude: `claude_review_decision`, `claude_review_confidence`, `claude_review_blocking_gap_count`, `claude_review_blocking_gaps`, `claude_review_required_edits`
- Codex/GPT: `codex_review_decision`, `codex_review_confidence`, `codex_review_blocking_gap_count`, `codex_review_blocking_gaps`, `codex_review_required_edits`

Fail closed if you cannot see all three reviewer decisions and blocking-gap summaries. Missing reviewer evidence is a workflow/tooling failure for this validation pass, not proof that the plan is ready.

Your job in this stage is to decide whether the plan is ready, needs only obvious editorial/structural correction, or needs human product/technical decisions before it can be ready.

Readiness standard:

A plan is READY only if an engineer can begin implementation without first resolving material product/business decisions or material technical design decisions, and if a reviewer can objectively validate success at the end.

A plan is NOT READY if any of these are true:

- The goal is materially ambiguous.
- The scope is too broad or lacks a smallest useful slice.
- Acceptance criteria are not concrete/testable enough.
- The plan does not classify the iteration as behaviour-facing or technical/engineering.
- A behaviour-facing or domain-policy plan lacks an `## Acceptance Scenarios / Feature Files` section with either named shared Cucumber feature file(s)/scenarios or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples.
- Important business decisions remain open.
- Implementation steps require major technical choices that are not made.
- The expected new capability or success validation is unclear.
- The plan expects shared acceptance `.feature` file edits but lacks a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

Correction policy:

Codex may only be asked to make obvious plan edits that do not require judgment calls, such as:

- tightening wording without changing meaning
- reorganizing existing content into clearer sections
- turning already-stated expectations into objective acceptance criteria
- making implicit boundaries explicit when the plan already clearly implies them
- removing duplication or contradiction when the intended meaning is obvious

Do not ask Codex to invent product policy, scope, UX, domain, data-model, integration, or technical-design decisions. If the plan needs those decisions, fail the validation and raise them for Matt.

Synthesis instructions:

1. First verify that all three reviewer decisions and blocking-gap summaries are visible in context. If any are missing, route to Matt/human input and explain that validation evidence was incomplete.
2. Compare the three reviews.
3. Include a reviewer decision table with each reviewer's decision, confidence, blocking gap count, and notes.
4. Identify consensus findings.
5. Correct reviewer findings that are wrong, too vague, duplicated, or not actually blocking.
6. Decide whether the plan is already ready, needs only obvious edits, or needs Matt's input.
7. If only obvious edits are needed, produce a concrete repair brief for Codex.
8. If Matt's input is needed, do not produce a repair brief as if Codex can solve it; list the decisions/questions clearly.

Voting/consensus guardrails:

- If two or more reviewers say NOT READY, you must not publish READY unless you explicitly quote or summarize each NOT READY blocker and explain why it is wrong or non-blocking.
- If any reviewer says NOT READY, include a `Reviewer objections addressed` section that accounts for every blocking gap from that reviewer.
- Do not treat successful reviewer node execution as readiness. Only the reviewer decision and findings content can support readiness.
- If your response cannot include a real synthesis report with the sections below, route to Matt/human input rather than READY.

Return a Markdown report with:

1. Provisional decision: READY, OBVIOUS FIXES NEEDED, or NEEDS MATT
2. Reviewer decision table: Reviewer, Decision, Confidence, Blocking gaps count, Notes
3. Consensus findings: 3-6 bullets
4. Reviewer objections addressed: account for every NOT READY blocking gap, or "No reviewer returned NOT READY"
5. Corrected findings: reviewer findings you changed, downgraded, combined, or rejected
6. Blocking gaps: numbered list, each with why it blocks implementation
7. Codex repair brief: exact instructions for obvious edits only, or "None"
8. Questions for Matt: decisions that need human input, or "None"
9. Validation checklist: what to check after any Codex update

At the end of your response, include one final JSON object for workflow routing. It must be the last thing in the response.

If the plan is already READY:

{"context_updates":{"plan_ready":true,"plan_needs_fix":false,"plan_needs_human":false}}

If the plan is NOT READY but Codex should apply only obvious fixes:

{"context_updates":{"plan_ready":false,"plan_needs_fix":true,"plan_needs_human":false}}

If the plan is NOT READY because Matt needs to answer questions or make decisions:

{"context_updates":{"plan_ready":false,"plan_needs_fix":false,"plan_needs_human":true}}
