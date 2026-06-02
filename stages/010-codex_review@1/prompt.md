Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT56VXDXGHN5GF62XH24BAJK
Pipeline progress: 8 of 23 stages completed

## Stage: read_plan_001_060
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 1 60 360 'original plan chunk 001-060'`
- Output:
  ```
  (14 lines omitted)
  After this iteration, Matt can manually cut production over to Postmark for member-message outbound delivery, inbound club-message email, rejection emails, and magic-link authentication using a documented runbook, while keeping Resend available as a rollback/fallback provider.
  
  ## Background / Context
  
  Iteration 008 added Postmark-backed outbound member-message delivery and Postmark delivery-status webhook handling. Postmark approval was still pending at the time, so ADR 0016 introduced Resend as a first-class switchable provider for production-like testing.
  
  Iteration 019 is the current delivery slice for inbound club messages by email. It deliberately proves inbound email with Resend first while keeping the application-side inbound email API provider-neutral enough for Postmark to replace or supplement Resend later.
  
  Postmark has now been approved. The product plan is to finish iteration 019 with Resend, observe that incoming messages work, then migrate production email to Postmark. This gives Memba evidence that both providers work fully and preserves a tested fallback path.
  
  ## Scope
  
  ### In scope
  
  - Add or complete Postmark inbound email support for club-message emails sent to `<club-slug>@clubs.memba.io`, for example `kmc@clubs.memba.io`.
  - Keep the member-facing inbound club-message address unchanged during the provider migration.
  - Translate Postmark inbound email payloads into the same provider-neutral inbound email command/API introduced for Resend in iteration 019.
  - Preserve iteration 019's accepted and rejected inbound-message behaviours for Postmark payloads: sender lookup, active-membership authorization, attachment rejection, plain-text requirement, quote/signature stripping, and rejection email delivery.
  - Ensure provider retry/idempotency handling works for Postmark inbound payloads using the provider message id or equivalent stable identifier.
  - Confirm outbound member-message delivery can be selected with `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` and still sends the required Postmark metadata for delivery-status correlation.
  - Confirm magic-link authentication email can be selected with `MEMBA_AUTH_EMAIL_PROVIDER=postmark` and uses the dedicated Postmark authentication message stream.
  - Confirm rejection emails sent by inbound club-message handling use the configured real email provider and work when Postmark is selected.
  - Update operational documentation and human todo/runbook material for Matt's manual production cutover: Postmark message streams, inbound domain/MX setup, webhook setup, Fly secrets, smoke tests, monitoring checks, and rollback to Resend.
  - Update ADR/documentation as needed to record Postmark as the intended primary provider while keeping Resend as a supported fallback.
  - Add automated tests for Postmark inbound parsing/translation and provider-selection/configuration behaviour.
  - Keep local development and automated tests deterministic by default; no real provider sends unless explicitly configured.
  - Keep `dev check` green.
  
  ### Out of scope
  
  - Actually changing production Fly secrets, DNS/MX records, or provider dashboard settings during delivery. Matt will perform the production cutover manually using the runbook.
  - Changing the member-facing inbound address away from `<club-slug>@clubs.memba.io`.
  - Changing the business rules for who may post by email or how unsupported inbound emails are rejected.
  - Adding new inbound email features: replies, threading, attachments, HTML preservation/conversion, channels/sub-groups, moderation, or custom club-owned inbound domains.
  - Removing Resend support from the codebase.
  - Switching automated acceptance tests to call real Postmark APIs.
  - Webhook authentication/signature verification unless it is already part of the existing provider-specific implementation and can be preserved without expanding the slice.
  - Designing new email templates or changing member-facing email copy except where provider-specific configuration requires it.
  
  ## Iteration Type
  
  Technical/engineering.
  
  The intended user-observable behaviour does not change. Members keep using the same club inbound address, message delivery behaviour, rejection rules, and magic-link sign-in flow. The slice changes provider plumbing, configuration, tests, and operational documentation so production can move from Resend to Postmark safely.
  
  ## Acceptance Scenarios / Feature Files
  
  BDD decision: Not useful for this slice.
  
  The stakeholder-visible behaviours are already or will be expressed by existing acceptance scenarios, especially the iteration 019 inbound club-message scenarios in `acceptance-tests/features/member_message_deliverability.feature` and existing member-message delivery/auth behaviours. This iteration should prove that the same behaviours work when the configured provider is Postmark rather than Resend. Provider payload parsing, configuration, and cutover runbooks are better covered by focused integration/unit tests and a manual smoke-test checklist than by adding new stakeholder-readable Gherkin.
  ```

## Stage: read_plan_061_120
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 61 120 360 'original plan chunk 061-120'`
- Output:
  ```
  (15 lines omitted)
  - Auth magic-link Postmark configuration requires the server token, auth from address, and dedicated auth message stream, and fails clearly when selected but incomplete.
  - Rejection emails sent by inbound club-message handling work when the selected real provider is Postmark.
  - Resend remains selectable for member-message delivery, auth email, and inbound handling so Matt can roll production back if the Postmark cutover fails.
  - Documentation names the exact environment variables/secrets Matt must set or change for the Postmark cutover and the exact Resend variables/secrets to restore for rollback.
  - Documentation names the required Postmark dashboard/DNS setup for outbound member broadcasts, auth magic links, inbound email routing for `clubs.memba.io`, and delivery-status webhooks.
  - Documentation includes a manual smoke-test script that proves auth email, outbound member-message email, inbound club-message email, rejection email, delivery-status webhook processing, and rollback readiness.
  - Routine local development and automated tests do not send real Postmark or Resend email by default.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  
  Decisions made during planning:
  
  - Switch all production email paths to Postmark, not only club-message email.
  - Keep `<club-slug>@clubs.memba.io` unchanged as the member-facing inbound address.
  - Delivery should prepare code and documentation only; Matt will perform production provider/DNS/secrets changes manually.
  - Keep Resend support as a tested fallback rather than removing it.
  
  ## Implementation Plan
  
  1. Start after iteration 019 is delivered and inbound club-message behaviour has been manually observed working with Resend.
  2. Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.
  3. Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and `docs/postmark-email.md`.
  4. Determine the cleanest Postmark inbound routing shape. Prefer keeping inbound-email handling separate from outbound delivery-status webhooks if Postmark's dashboard supports separate inbound and delivery-status webhook URLs; otherwise make the shared Postmark route dispatch safely by payload shape.
  5. Add a Postmark inbound parser/controller/dispatcher that maps realistic Postmark inbound payload fields to the provider-neutral inbound email structure: provider name, provider message id, sender, recipients, subject, plain text, HTML body if present, attachment metadata, and useful headers.
  6. Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
  7. Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
  8. Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
  9. Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
  10. Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
  11. Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
  12. Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
  13. Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
  14. Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
  15. Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
  16. Run `dev check`.
  
  ## Open Technical Decisions
  
  Implementation should investigate and decide:
  
  - The exact Postmark inbound webhook payload shape and which field is the best stable provider message id for idempotency.
  - Whether Postmark inbound email and delivery-status events should use two separate routes or one dispatching route, based on Postmark configuration capabilities and the existing `/webhooks/postmark` controller.
  - The exact Postmark inbound domain/MX setup needed to preserve `<club-slug>@clubs.memba.io`.
  - Whether Postmark inbound webhooks provide attachment metadata without downloading attachments, and how to detect attachments early enough to preserve the iteration 019 rejection rule.
  - Whether any provider-specific inbound authentication is available and already configured; do not expand into a security iteration unless small and non-disruptive.
  
  ## New Capability
  ```

## Stage: read_plan_121_180
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 121 180 360 'original plan chunk 121-180'`
- Output:
  ```
  PLAN_PATH=docs/iterations/020-migrate-production-email-to-postmark/plan.md
  PLAN_TOTAL_LINES=147
  PLAN_CHUNK=original plan chunk 121-180
  PLAN_CHUNK_LINES=121-180
  
  
  Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback.
  
  ## Validation Plan
  
  - Run focused tests for Postmark inbound payload parsing/translation.
  - Run focused tests for provider-neutral inbound command/API regressions from iteration 019.
  - Run focused tests for Resend inbound parsing to confirm fallback support still works.
  - Run focused tests for Postmark outbound member-message payload metadata and delivery-status webhook correlation.
  - Run focused tests for Postmark auth email configuration and missing-config errors.
  - Run `dev check`.
  - Manual cutover smoke test from the runbook after Matt changes production configuration:
    1. Confirm Postmark outbound member-message stream, auth stream, inbound routing for `clubs.memba.io`, and webhooks are configured.
    2. Set production secrets to select Postmark for member-message delivery and auth email.
    3. Send a magic link to a controlled inbox, confirm receipt from the Postmark auth sender, and sign in successfully.
    4. Send a member message from the web UI, confirm Postmark accepts and delivers it, and confirm delivery-status webhook updates Memba.
    5. Email `kmc@clubs.memba.io` from an active member address, confirm Memba creates and distributes the club message.
    6. Email `kmc@clubs.memba.io` from an unsupported sender or with an unsupported attachment, confirm no club message is created and the rejection email is delivered through Postmark.
    7. Confirm Resend rollback instructions are complete and the required Resend secrets/webhooks are still available.
  
  ## Risks / Follow-ups
  
  - Postmark inbound payloads may differ enough from Resend that the provider-neutral API needs small adjustments. Keep changes provider-neutral and preserve Resend tests.
  - Inbound domain/MX setup for `clubs.memba.io` may require DNS/provider dashboard work that cannot be completed by code delivery alone; document it clearly for Matt's manual cutover.
  - Production cutover risk includes missed MX propagation, webhook misconfiguration, missing secrets, or sender-domain reputation issues. The runbook and rollback path mitigate this.
  - Webhook authentication remains a known follow-up security concern from ADR 0016 and the provider webhook authentication kaizen note.
  - Keeping both providers increases maintenance cost, but it is valuable while Memba is still proving deliverability and provider fit.
  ```

## Stage: read_plan_181_240
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 181 240 360 'original plan chunk 181-240'`
- Output:
  ```
  PLAN_PATH=docs/iterations/020-migrate-production-email-to-postmark/plan.md
  PLAN_TOTAL_LINES=147
  PLAN_CHUNK=original plan chunk 181-240
  PLAN_CHUNK_LINES=181-240
  
  (no plan lines in this chunk)
  ```

## Stage: read_plan_241_300
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 241 300 360 'original plan chunk 241-300'`
- Output:
  ```
  PLAN_PATH=docs/iterations/020-migrate-production-email-to-postmark/plan.md
  PLAN_TOTAL_LINES=147
  PLAN_CHUNK=original plan chunk 241-300
  PLAN_CHUNK_LINES=241-300
  
  (no plan lines in this chunk)
  ```

## Stage: read_plan_301_360
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/020-migrate-production-email-to-postmark/plan.md' 301 360 360 'original plan chunk 301-360'`
- Output:
  ```
  PLAN_PATH=docs/iterations/020-migrate-production-email-to-postmark/plan.md
  PLAN_TOTAL_LINES=147
  PLAN_CHUNK=original plan chunk 301-360
  PLAN_CHUNK_LINES=301-360
  
  (no plan lines in this chunk)
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 5.2k in / 1.1k out
- Response:
  > {"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.7k in / 5.9k out
- Response:
  > # Independent Plan Review: Iteration 020
  > 
  > ## Decision: READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > None.
  > 
  > ## Non-Blocking Improvements
  > 
  > 1. **Clarity on existing vs. new implementation**: The plan could make more explicit which Postmark capabilities are already implemented (outbound member messages from iteration 008), which need implementation (inbound email), and which need verification/testing (auth email, rejection email paths). This is inferable from "verify or add" language but not completely explicit.
  > 
  > 2. **Dependency precision**: The plan says "start after iteration 019" but could be more explicit: "This iteration cannot start until iteration 019 is delivered AND inbound email with Resend has been observed working in production." The background implies this, but stating it explicitly in the implementation plan would remove ambiguity.
  > 
  > 3. **Effort indication**: The plan doesn't include an estimate or complexity signal. This appears to be a 2-4 day technical slice but isn't stated.
  > 
  > These improvements would enhance clarity but do not block implementation.
  > 
  > ## Smallest Viable Iteration
  > 
  > **This plan already represents the smallest viable iteration for the stated goal.**
  > 
  > The goal is enabling Matt to cut production email over to Postmark with a documented runbook and rollback path. To achieve this safely, the iteration must:
  > 
  > - Add Postmark inbound email support (the main new capability)
  > - Verify Postmark outbound member messages still work correctly
  > - Verify Postmark auth email configuration and behavior
  > - Verify rejection emails work through Postmark
  > - Keep Resend as a tested fallback
  > - Document the complete cutover and rollback procedures
  > 
  > Any smaller scope would leave an incomplete migration that cannot be safely executed. You cannot migrate only some email types while maintaining the member-facing address `<club-slug>@clubs.memba.io`.
  > 
  > The plan correctly excludes actual production changes (out of scope for delivery) and new features (out of scope for this migration).
  > 
  > ## Required Plan Edits
  > 
  > **None.**
  > 
  > The plan is ready for implementation as written.
  > 
  > ## Validation Plan Assessment
  > 
  > The plan includes a comprehensive validation strategy (lines 121-147):
  > 
  > **Automated validation:**
  > - Focused tests for Postmark inbound parsing/translation
  > - Regression tests for provider-neutral API (iteration 019)
  > - Regression tests for Resend fallback
  > - Tests for Postmark outbound metadata and delivery-status correlation
  > - Tests for Postmark auth configuration and error handling
  > - `dev check` passing
  > 
  > **Manual validation:**
  > A 7-step smoke test covering:
  > 1. Postmark dashboard/DNS/webhook configuration verification
  > 2. Production secrets correctly set for Postmark
  > 3. Magic-link auth email delivery and sign-in flow
  > 4. Outbound member message delivery and delivery-status webhook updates
  > 5. Inbound club messages from active members
  > 6. Rejection emails for unsupported senders/attachments
  > 7. Rollback path verification (Resend secrets/webhooks still available)
  > 
  > This validation plan is sufficient to prove:
  > - All email types work through Postmark
  > - Existing behavior is preserved
  > - Resend fallback remains functional
  > - Matt can safely perform the production cutover
  > 
  > ## Detailed Assessment
  > 
  > ### 1. Goal Clarity ✓
  > 
  > **Goal:** "After this iteration, Matt can manually cut production over to Postmark for member-message outbound delivery, inbound club-message email, rejection emails, and magic-link authentication using a documented runbook, while keeping Resend available as a rollback/fallback provider."
  > 
  > - Clear beneficiary: Matt (operator)
  > - Clear outcome: Can perform manual production cutover
  > - Explicit about what is enabled vs. executed
  > - User-facing behavior unchanged (technical/engineering iteration)
  > 
  > ### 2. Scope Focus ✓
  > 
  > **In scope:**
  > - Postmark inbound email support for club messages
  > - Provider-neutral translation of Postmark payloads
  > - Preservation of iteration 019 behaviors (authorization, rejection, idempotency)
  > - Outbound member-message delivery via Postmark (verification)
  > - Magic-link auth via Postmark (verification)
  > - Rejection email handling via Postmark
  > - Complete operational documentation and runbook
  > - Automated tests
  > - Resend fallback preservation
  > 
  > **Out of scope:**
  > - Actual production cutover (Matt performs manually)
  > - Business rule changes
  > - New inbound email features
  > - Removing Resend support
  > - Webhook authentication expansion
  > 
  > The scope is coherent, focused on migration enablement, and appropriately sized. It addresses all email types in a single slice to enable a complete migration while keeping behavior unchanged.
  > 
  > ### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓
  > 
  > **Acceptance criteria** (lines 61-120): Concrete, testable, and comprehensive:
  > - Postmark inbound parsing/translation works
  > - Sender authorization preserved
  > - Attachments/non-plain-text rejected appropriately
  > - Idempotency handling works
  > - Provider selection configurable for all email types
  > - Configuration failures are clear
  > - Resend remains selectable for rollback
  > - Documentation specifies exact variables/secrets/setup
  > - Manual smoke tests documented
  > - Local dev remains deterministic
  > - `dev check` passes
  > 
  > Covers happy paths, edge cases, error states, configuration, and rollback.
  > 
  > **BDD decision** (lines 001-060): Explicitly addressed with clear rationale:
  > - Iteration type: Technical/engineering
  > - User behavior unchanged
  > - Existing acceptance scenarios (iteration 019) already express the behavior
  > - Provider plumbing better tested with integration/unit tests
  > - No new Gherkin scenarios needed
  > 
  > This decision is appropriate and well-justified.
  > 
  > **Business decisions** (lines 061-120): All resolved during planning:
  > - Migrate all email paths to Postmark (not just club messages)
  > - Keep `<club-slug>@clubs.memba.io` unchanged
  > - Delivery prepares code/docs only; Matt performs cutover manually
  > - Preserve Resend as tested fallback
  > 
  > ### 4. Implementation Plan and Technical Decisions ✓
  > 
  > **Implementation plan** (lines 061-120): 16 detailed, ordered steps:
  > 1. Start after iteration 019 completion and observation
  > 2. Inspect iteration 019's provider-neutral API/idempotency/tests
  > 3. Inspect existing Postmark capabilities
  > 4. Determine Postmark inbound routing approach
  > 5. Add Postmark inbound parser/controller
  > 6. Reuse provider-neutral command/API
  > 7. Add Postmark idempotency support
  > 8. Add tests for Postmark inbound
  > 9. Verify/add tests for Postmark outbound metadata
  > 10. Verify/add tests for Postmark auth configuration
  > 11. Verify rejection email delivery
  > 12. Update `docs/postmark-email.md`
  > 13. Update/add runbook documentation
  > 14. Update ADRs as needed
  > 15. Run targeted tests
  > 16. Run `dev check`
  > 
  > Names specific files (`docs/postmark-email.md`, `docs/human-todo.md`), modules (inbound parser/controller, provider-neutral API), and integration points (delivery-status webhooks, auth email configuration).
  > 
  > **Technical decisions** (lines 121-180): Appropriately scoped as implementation-time investigation questions:
  > - Postmark inbound payload shape and idempotency field
  > - Routing approach (separate vs. dispatching webhook route)
  > - Domain/MX setup for `clubs.memba.io`
  > - Attachment metadata availability
  > - Provider-specific inbound authentication (if available and non-disruptive)
  > 
  > These are discovery questions requiring Postmark API inspection, not blocking design decisions.
  > 
  > ### 5. Expected Capability and Validation ✓
  > 
  > **New capability** (lines 121-180):
  > "Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback."
  > 
  > Clear before/after state:
  > - Before: Resend for inbound; Postmark for outbound but not fully validated/documented
  > - After: All email paths work with Postmark, fully tested and documented with cutover runbook
  > 
  > **Stop condition:** Clear - all tests pass, runbook documented, `dev check` green.
  > 
  > ### Risks/Follow-ups
  > 
  > The plan acknowledges realistic risks (lines 121-180):
  > - Postmark payload differences may require API adjustments
  > - DNS/MX setup requires manual work
  > - Production cutover risks (mitigated by runbook/rollback)
  > - Webhook authentication remains a follow-up concern
  > - Dual-provider maintenance cost (accepted as valuable during provider validation)
  > 
  > Thoughtful and realistic risk assessment with documented mitigations.
  > 
  > ## Alignment with Gemini Review
  > 
  > The Gemini review reached the same conclusion: READY with High confidence and 0 blocking gaps. Both reviews agree this plan is thorough, well-structured, and ready for implementation.
  > 
  > {"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 0 |
| claude_review_blocking_gaps | None |
| claude_review_confidence | High |
| claude_review_decision | READY |
| claude_review_required_edits | None |
| gemini_review_blocking_gap_count | 0 |
| gemini_review_blocking_gaps | None |
| gemini_review_confidence | High |
| gemini_review_decision | READY |
| gemini_review_required_edits | None |


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
