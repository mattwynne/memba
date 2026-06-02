Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KT551990W3YWBP2M8GM7NWW2
Pipeline progress: 9 of 23 stages completed

## Stage: read_plan_001_060
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 1 60 360 'original plan chunk 001-060'`
- Output:
  ```
  (14 lines omitted)
  After this iteration, Alice can email `kmc@clubs.memba.io` from any email address on her person record, and Memba creates a Kootenay Mountaineering Club message from that email and distributes it to the club's active members using the same delivery and visibility rules as a message composed in the web UI.
  
  ## Background / Context
  
  Members can already compose club messages in the browser and receive club-message email. Clubs now have slugs and member-facing subdomains, so there is enough club identity to introduce a simple club-specific inbound email address.
  
  The problem captured in `docs/problems/2026-06-02-send-club-message-by-email.md` is that members cannot create a club message by emailing Memba. The first useful slice should prove the core workflow without designing future replies, channels, rich HTML, attachments, or custom inbound domains.
  
  Production currently uses Resend. Postmark is present in the codebase but still unproven for production use. This iteration should integrate with Resend inbound webhooks now, while keeping the app-side inbound email API provider-neutral enough that Postmark can replace or supplement Resend later.
  
  ## Scope
  
  ### In scope
  
  - Add a club inbound address convention: `<club-slug>@clubs.memba.io`, for example `kmc@clubs.memba.io`.
  - Treat that address as the club's implicit everyone address for now.
  - Add a provider-neutral internal command/API for receiving an inbound club-message email.
  - Add a Resend inbound webhook endpoint/parser that translates Resend inbound payloads into the provider-neutral internal command/API.
  - Identify the sender from any email address on a person record, primary or alternate.
  - Authorize inbound posting only when the identified person is an active member of the destination club.
  - Create a new club message from an accepted inbound email.
  - Address the created message to the same active club-member audience as a web-composed club message.
  - Distribute accepted inbound messages through the existing outbound email delivery path.
  - Preserve the same member-visible message detail, delivery status, and audit semantics as web-composed club messages.
  - Use only the inbound email's non-blank `text/plain` body as the message body.
  - Ignore inbound `text/html` for this slice and do not implement HTML-to-text conversion.
  - Strip common quoted prior-message text and signatures from the plain-text body before validating and storing it.
  - Reject inbound emails with no usable plain-text body after quote/signature stripping.
  - Reject inbound emails that include attachments.
  - Reject inbound emails from unknown senders, inactive members, and known people who are not active members of the destination club.
  - Send a polite rejection email to the sender when the inbound email is not posted, including the reason and support/contact guidance.
  - Do not send a separate confirmation email for accepted messages; the sender receives the normal club-message copy if included in the audience.
  - Add or update tests and acceptance support for Resend inbound webhook handling and inbound club-message behaviour.
  - Keep `dev check` green.
  
  ### Out of scope
  
  - Replies to existing message emails.
  - Threading or conversation grouping.
  - Attachments support.
  - Preserving, sanitising, rendering, or forwarding inbound HTML formatting.
  - HTML-to-text conversion.
  - Channels or sub-groups such as `everyone@kmc.clubs.memba.io`.
  - Club custom inbound domains such as `all@members.kootenaymountaineeringclub.ca`.
  - Moderation queues or hold-for-review workflows.
  - Public contact messages from unknown senders.
  - Final deliverability/reputation strategy for inbound or outbound domains.
  - Switching production outbound delivery from Resend to Postmark.
  
  ## Iteration Type
  ```

## Stage: read_plan_061_120
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 61 120 360 'original plan chunk 061-120'`
- Output:
  ```
  (14 lines omitted)
  
  Update this shared Cucumber feature file:
  
  - `acceptance-tests/features/member_message_deliverability.feature`
  
  Add `@wip` scenarios under new inbound-email rules until implementation catches up:
  
  - Alice emails `kmc@clubs.memba.io` and the email becomes a KMC club message sent to KMC members only.
  - Alice sends from an alternate email address on her person record and Memba still posts the message as Alice.
  - An unknown sender emails `kmc@clubs.memba.io` and receives a rejection; no club message is created.
  - Pat, a known member of another club but not KMC, emails `kmc@clubs.memba.io` and receives a rejection; no KMC message is created.
  - Alice sends an email with an attachment and receives an attachment-not-supported rejection; no club message is created.
  - Alice sends an email whose plain-text body contains a signature and quoted prior content; Memba posts only the new message text.
  - Alice sends an HTML-only email and receives a plain-text-required rejection; no club message is created.
  
  Matt should review the added scenario language as domain language before treating this plan as final.
  
  ## Allowed acceptance feature changes
  
  - `acceptance-tests/features/member_message_deliverability.feature`: add `@wip` inbound-email scenarios documenting accepted inbound posting, alternate sender addresses, rejection for unknown/non-member senders, unsupported attachments, quote/signature stripping, and HTML-only rejection. The `@wip` tags keep planning-time checks green until delivery implements the supporting steps and application behaviour.
  - Acceptance support and step definitions may be updated during implementation to simulate Resend inbound webhook payloads, inspect rejection emails in the test mailbox, and assert that no club message was created for rejected inbound email.
  
  ## Acceptance Criteria
  
  - `kmc@clubs.memba.io` resolves to Kootenay Mountaineering Club by the existing `kmc` club slug.
  - Unknown club slugs in inbound recipient addresses are rejected without creating a message.
  - An inbound email to `kmc@clubs.memba.io` from Alice's primary email address creates a KMC club message from Alice.
  - An inbound email to `kmc@clubs.memba.io` from one of Alice's alternate email addresses also creates a KMC club message from Alice.
  - Accepted inbound messages are visible anywhere web-composed club messages are visible to active KMC members.
  - Accepted inbound messages address the same active club-member audience as web-composed club messages.
  - Accepted inbound messages are delivered through the existing outbound delivery provider path.
  - Accepted inbound messages create the same kind of delivery records/statuses as web-composed club messages.
  - Accepted inbound messages do not address members of other clubs.
  - Memba does not send a separate acceptance confirmation email.
  - The inbound email subject becomes the club message subject.
  - The inbound email `text/plain` body, after quote/signature stripping, becomes the club message body.
  - Inbound `text/html` is ignored in this slice.
  - Memba does not implement HTML-to-text conversion in this slice.
  - If there is no non-blank plain-text body after quote/signature stripping, no club message is created and the sender receives a clear rejection email.
  - If the inbound email has attachments, no club message is created and the sender receives a clear rejection email explaining attachments are not supported yet.
  - If the sender email address is unknown to Memba, no club message is created and the sender receives a polite rejection email with support/contact guidance.
  - If the sender email address belongs to a person who is not an active member of the destination club, no club message is created and the sender receives a polite rejection email with support/contact guidance.
  - If the sender email address belongs to an inactive member of the destination club, no club message is created and the sender receives a polite rejection email with support/contact guidance.
  - Rejection emails include enough reason for the sender to know why their message was not posted, without exposing private club data unnecessarily.
  - Resend inbound webhook payloads are accepted by a dedicated endpoint and translated into the provider-neutral inbound email command/API.
  - The provider-neutral inbound email command/API is covered by tests independently from the Resend payload shape.
  - Resend-specific parsing/routing is covered by controller/parser tests.
  - `dev check` passes.
  
  ## Open Business Decisions
  ```

## Stage: read_plan_121_180
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 121 180 360 'original plan chunk 121-180'`
- Output:
  ```
  (15 lines omitted)
  - Whether attachments should be stored and shown, stripped with a warning, or handled by a separate file workflow.
  - Whether unknown senders should eventually become public contact messages or access requests instead of rejections.
  
  ## Implementation Plan
  
  1. Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller, router webhook scope, and current acceptance support.
  2. Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, and provider name.
  3. Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
  4. Add sender resolution that finds a person by any primary or alternate email address.
  5. Add active-membership authorization for the resolved sender and destination club.
  6. Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
  7. Add plain-text body normalization:
     - require a non-blank `text/plain` part;
     - ignore `text/html`;
     - do not implement HTML-to-text conversion;
     - strip common signatures and quoted prior-message text;
     - reject if the resulting body is blank.
  8. Add attachment rejection before message creation when inbound payload includes any attachments.
  9. Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
  10. Add a Resend inbound webhook route/controller/parser that validates and accepts Resend inbound payloads according to the available Resend payload/signature conventions already used in production configuration.
  11. Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
  12. Add tests for provider-neutral inbound behaviour:
      - accepted primary address;
      - accepted alternate address;
      - unknown sender rejection;
      - non-member rejection;
      - inactive-member rejection;
      - attachments rejection;
      - missing/blank plain text rejection;
      - HTML-only rejection without conversion;
      - quote/signature stripping;
      - unknown club slug rejection.
  13. Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, and rejection paths.
  14. Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
  15. Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
  16. Run `dev check`.
  
  ## Open Technical Decisions
  
  None expected to block implementation.
  
  Implementation should investigate and decide details for:
  
  - The exact Resend inbound webhook payload fields available for text body, HTML body, attachments, headers, message id, and envelope recipients.
  - Whether Resend inbound webhooks require signature verification or share existing webhook verification mechanisms.
  - The minimal safe quote/signature stripping approach for plain text. Prefer conservative stripping over complex parsing.
  - Whether rejection emails should be sent synchronously during webhook handling or via existing asynchronous delivery paths.
  - How to avoid provider retries creating duplicate messages if Resend retries the same inbound webhook. Prefer idempotency based on provider message id where available.
  
  ## New Capability
  ```

## Stage: read_plan_181_240
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 181 240 360 'original plan chunk 181-240'`
- Output:
  ```
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  PLAN_TOTAL_LINES=212
  PLAN_CHUNK=original plan chunk 181-240
  PLAN_CHUNK_LINES=181-240
  
  
  A member can post to the whole club by email, using the club's simple slug-based inbound address. Memba can receive provider inbound email payloads, route them to clubs, authorize senders, create normal club messages, and reject unsupported inbound emails politely.
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted messaging context tests for the provider-neutral inbound email command/API.
  - Run targeted Resend inbound webhook controller/parser tests.
  - Run targeted mailer tests for rejection emails.
  - Run Cucumber configuration tests to confirm `@wip` scenarios are excluded from the default acceptance run until implemented.
  - After implementation removes or narrows `@wip` tags, run the affected Cucumber feature file.
  - Manual demo:
    1. Start the app locally with the local/test mailer.
    2. Ensure Kootenay Mountaineering Club has slug `kmc` and Alice is an active member with primary and alternate email addresses.
    3. Submit a realistic Resend inbound webhook payload representing Alice emailing `kmc@clubs.memba.io` with subject `Trip planning night` and a plain-text body.
    4. Confirm the message appears in KMC member views as a normal club message from Alice.
    5. Confirm KMC active members receive outbound club-message email and Nelson Paddling Club members do not.
    6. Submit the same example from Alice's alternate email address and confirm it is posted as Alice.
    7. Submit examples from an unknown sender and from Pat, who is not a KMC member, and confirm no message appears and each sender receives a rejection email.
    8. Submit an example with an attachment and confirm it is rejected with an attachment-not-supported email.
    9. Submit an HTML-only example and confirm it is rejected with a plain-text-required email.
    10. Submit an example with quoted content/signature and confirm only the new message text appears in the posted club message.
  
  ## Risks / Follow-ups
  
  - Resend inbound webhook support may have payload or verification details that differ from the current outbound/delivery-status assumptions. Keep the Resend-specific parser isolated.
  - Inbound webhooks may be retried. Without idempotency, duplicate emails could create duplicate club messages.
  - Quote/signature stripping can easily become too aggressive or too weak. Keep this conservative and covered by examples.
  - Rejection emails can create backscatter if sent to spoofed senders. This is acceptable for the first slice only if the implementation uses provider guidance and avoids replying to obviously invalid automated senders where practical.
  - Ignoring HTML is a deliberate short-term simplification. A later rich-content iteration should preserve, sanitise, render, and forward safe HTML rather than adding throwaway HTML-to-text conversion now.
  - Attachments are rejected for now. A later iteration should decide storage, scanning, visibility, and delivery semantics.
  - Future channel/sub-group addressing and custom club-owned inbound domains may change address generation and routing.
  ```

## Stage: read_plan_241_300
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 241 300 360 'original plan chunk 241-300'`
- Output:
  ```
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  PLAN_TOTAL_LINES=212
  PLAN_CHUNK=original plan chunk 241-300
  PLAN_CHUNK_LINES=241-300
  
  (no plan lines in this chunk)
  ```

## Stage: read_plan_301_360
- Status: succeeded
- Handler: command
- Script: `.fabro/workflows/plan-validation/scripts/print_plan_chunk.sh 'docs/iterations/019-inbound-club-messages-by-email/plan.md' 301 360 360 'original plan chunk 301-360'`
- Output:
  ```
  PLAN_PATH=docs/iterations/019-inbound-club-messages-by-email/plan.md
  PLAN_TOTAL_LINES=212
  PLAN_CHUNK=original plan chunk 301-360
  PLAN_CHUNK_LINES=301-360
  
  (no plan lines in this chunk)
  ```

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gemini-3.1-pro-preview
- Tokens: 11.5k in / 4.9k out
- Response:
  > {
  >   "context_updates": {
  >     "gemini_review_decision": "NOT READY",
  >     "gemini_review_confidence": "High",
  >     "gemini_review_blocking_gap_count": 2,
  >     "gemini_review_blocking_gaps": "Open technical decisions on idempotency approach and Resend payload schema are unresolved; Missing explicit database schema and migration steps for storing provider_message_id to support idempotency.",
  >     "gemini_review_required_edits": "Resolve the open technical decisions regarding Resend payload fields and idempotency mechanism; Add explicit implementation steps for Ecto migrations to store provider_message_id and enforce unique constraints to prevent duplicate messages from webhook retries."
  >   }
  > }

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 6.3k in / 3.6k out
- Response:
  > # Independent Plan Review: Iteration 019 - Inbound Club Messages by Email
  > 
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > ## Blocking Gaps
  > 
  > 1. **Idempotency mechanism unresolved**: The plan acknowledges webhook retry risks and duplicate message creation but does not include database schema changes or implementation steps to prevent duplicates. No migration is specified for storing `provider_message_id`, no unique constraints, no deduplication logic. The "Open Technical Decisions" section defers this to implementation investigation, but this is an architectural decision that affects data modeling and must be resolved during planning.
  > 
  > 2. **Resend payload schema unknown**: The plan defers investigating "exact Resend inbound webhook payload fields" to implementation time. Field names for text body, HTML body, attachments, headers, message ID, and envelope recipients must be researched and documented during planning so implementation steps can reference specific field mappings rather than generic "translate payload" guidance.
  > 
  > 3. **Webhook signature verification undefined**: Security verification approach should be decided before implementation. The plan asks whether "Resend inbound webhooks require signature verification or share existing webhook verification mechanisms" but leaves this open. This is a security-critical decision that belongs in planning, not implementation.
  > 
  > ## Non-blocking Improvements
  > 
  > 1. **Rejection email delivery timing**: The plan leaves synchronous vs. asynchronous rejection email delivery as an implementation-time decision. While this can be refactored later, deciding upfront would result in cleaner initial implementation.
  > 
  > 2. **Quote/signature stripping specificity**: The plan says "prefer conservative stripping" but could name a specific library, pattern, or reference implementation to reduce implementation uncertainty.
  > 
  > 3. **Alternate email lookup strategy**: The plan doesn't specify whether alternate email lookup should check person records, person_emails join table, or both. This detail would help implementation.
  > 
  > ## Smallest Viable Iteration
  > 
  > The current scope already represents a reasonable minimum for this capability. The only way to make it meaningfully smaller would be to defer alternate email address support, skip quote/signature stripping, and accept messages in full with basic rejections. This would reduce polish and user value by ~25% but save only ~20% implementation effort.
  > 
  > **Recommendation**: Keep current scope but resolve blocking gaps rather than cutting scope.
  > 
  > ## Required Plan Edits
  > 
  > 1. **Research and document Resend webhook payload structure** before finalizing the plan:
  >    - List actual field names for: text body, HTML body, attachments, headers, message ID, envelope from/to, timestamp
  >    - Document payload examples in the plan or reference Resend API documentation
  >    - Update implementation steps 10-11 to reference specific field mappings
  > 
  > 2. **Decide idempotency approach** and add explicit implementation steps:
  >    - Add step 2a: "Create migration to add `provider_message_id` string field to messages table (or new `inbound_emails` tracking table)"
  >    - Add step 2b: "Add unique index on `provider_message_id` scoped to provider name"
  >    - Add step 6a: "Before creating message, check if provider_message_id already exists; if duplicate, log and return success without creating duplicate message"
  >    - Add test case to step 12: "duplicate webhook delivery with same provider_message_id creates only one message"
  >    - Remove idempotency from "Open Technical Decisions" and document chosen approach
  > 
  > 3. **Decide and document webhook verification**:
  >    - Research whether Resend inbound webhooks use the same verification mechanism as delivery status webhooks
  >    - Document required verification steps (signature header name, algorithm, secret source)
  >    - Add verification logic to implementation step 10 or reference existing verification helper
  >    - Remove webhook verification from "Open Technical Decisions"
  > 
  > 4. **Move resolved decisions** from "Open Technical Decisions" to plan body or accept them as implementation details:
  >    - If rejection emails should be asynchronous (likely better for webhook response time), state this in step 9
  >    - If quote/signature stripping should use a specific approach, name it; otherwise accept "conservative, example-covered" as sufficient
  > 
  > ## Validation Plan
  > 
  > After the required edits, the plan will be ready when:
  > 
  > 1. ✅ Resend payload fields are documented with specific field names
  > 2. ✅ Database migration for provider_message_id is in implementation plan
  > 3. ✅ Idempotency check is in implementation plan
  > 4. ✅ Webhook verification approach is documented
  > 5. ✅ Implementation plan includes test for duplicate webhook prevention
  > 6. ✅ "Open Technical Decisions" section no longer lists blocking decisions
  > 
  > The existing validation plan (dev check, targeted tests, Cucumber scenarios, manual demo) is thorough and appropriate once these gaps are filled.
  > 
  > **After implementation completes**, success is proven by:
  > - All @wip tags removed from Cucumber scenarios
  > - `member_message_deliverability.feature` passes with inbound scenarios
  > - Manual demo confirms: inbound email creates club message, rejections work, duplicates prevented, alternate addresses work
  > - `dev check` passes
  > 
  > ---
  > 
  > {"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Idempotency mechanism unresolved - no database schema or implementation steps for preventing duplicate messages from webhook retries; Resend webhook payload schema unknown - field names must be researched and documented during planning; Webhook signature verification approach undefined - security-critical decision must be resolved before implementation","claude_review_required_edits":"Research and document Resend inbound webhook payload field names and structure; Add database migration for provider_message_id with unique constraint to implementation plan; Add idempotency check logic to implementation plan; Decide and document webhook signature verification approach; Add test case for duplicate webhook prevention"}}

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.9k in / 2.3k out
- Response:
  > {
  >   "context_updates": {
  >     "codex_review_decision": "NOT READY",
  >     "codex_review_confidence": "High",
  >     "codex_review_blocking_gap_count": 5,
  >     "codex_review_blocking_gaps": "Plan evidence is incomplete because multiple read chunks contain omitted lines; Resend inbound webhook payload field mapping is unresolved; Webhook signature verification/security approach is unresolved; Idempotency data model and duplicate webhook behaviour are unresolved; Plan says Matt must review scenario language before final but that review is not shown as complete",
  >     "codex_review_required_edits": "Provide full unomitted plan text for validation; Document Resend inbound payload schema and exact mappings; Decide and document webhook verification using specific headers/secrets/raw body handling; Add migration/data model and unique constraint plus duplicate handling and tests; Complete or remove the pending Matt scenario-language review requirement"
  >   }
  > }

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 3 |
| claude_review_blocking_gaps | Idempotency mechanism unresolved - no database schema or implementation steps for preventing duplicate messages from webhook retries; Resend webhook payload schema unknown - field names must be researched and documented during planning; Webhook signature verification approach undefined - security-critical decision must be resolved before implementation |
| claude_review_confidence | High |
| claude_review_decision | NOT READY |
| claude_review_required_edits | Research and document Resend inbound webhook payload field names and structure; Add database migration for provider_message_id with unique constraint to implementation plan; Add idempotency check logic to implementation plan; Decide and document webhook signature verification approach; Add test case for duplicate webhook prevention |
| codex_review_blocking_gap_count | 5 |
| codex_review_blocking_gaps | Plan evidence is incomplete because multiple read chunks contain omitted lines; Resend inbound webhook payload field mapping is unresolved; Webhook signature verification/security approach is unresolved; Idempotency data model and duplicate webhook behaviour are unresolved; Plan says Matt must review scenario language before final but that review is not shown as complete |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Provide full unomitted plan text for validation; Document Resend inbound payload schema and exact mappings; Decide and document webhook verification using specific headers/secrets/raw body handling; Add migration/data model and unique constraint plus duplicate handling and tests; Complete or remove the pending Matt scenario-language review requirement |
| gemini_review_blocking_gap_count | 2 |
| gemini_review_blocking_gaps | Open technical decisions on idempotency approach and Resend payload schema are unresolved; Missing explicit database schema and migration steps for storing provider_message_id to support idempotency. |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Resolve the open technical decisions regarding Resend payload fields and idempotency mechanism; Add explicit implementation steps for Ecto migrations to store provider_message_id and enforce unique constraints to prevent duplicate messages from webhook retries. |


You are Claude Opus acting as the repair coordinator for an iteration plan validation loop.

Use the plan text and the three model reviews in context.

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
