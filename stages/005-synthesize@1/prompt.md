Goal: Validate that an iteration plan is ready for implementation and mark it validated without starting implementation
Run ID: 01KVHYRARQ390FNNBMTBKT9W4W
Pipeline progress: 3 of 10 stages completed

## Stage: gemini_review
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 10.6k in / 2.6k out
- Response:
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md` lines 1–118.
  > 
  > ## Blocking gaps
  > 
  > 1. **Core technical decisions are explicitly unresolved.**  
  >    The plan’s `## Open Technical Decisions` section leaves follow storage, unsubscribe token mechanism, and reply-delivery factoring undecided. These are not merely incidental details: they affect data modeling, migrations/projections, security, email links, tests, and integration boundaries.
  > 
  > 2. **Email stop-follow/unsubscribe behavior is not specified enough to implement safely.**  
  >    The plan requires members to stop following from a reply email, but does not define the authorization/token behavior, invalid/expired token handling, idempotency, whether login is required, success/failure UX, or behavior for former/non-current members.
  > 
  > 3. **Follow/unfollow permissions and edge/error states are incomplete.**  
  >    Acceptance criteria cover happy paths and delivery outcomes, but do not objectively specify who may follow/unfollow a conversation, what happens if a non-member or removed member attempts it, or how repeated follow/unfollow commands behave.
  > 
  > ## Non-blocking improvements
  > 
  > 1. Name likely implementation files/modules/tests where possible, especially the messaging command/event modules, follow projection/read model, reply delivery path, email template, LiveView/controller surface, and acceptance/browser tests.
  > 2. Add explicit UI state expectations for the message-detail follow control: initial state, followed state, unfollowed state, loading/error behavior if relevant.
  > 3. Clarify whether the no-reply `Reply-To` guidance from the business decision should be asserted in tests for this iteration.
  > 4. Add a brief migration/projection backfill note if existing conversations from iteration 039 may exist when this lands.
  > 
  > ## Smallest viable iteration
  > 
  > The smallest useful slice is:
  > 
  > - Persist per-member/per-conversation follow state.
  > - Auto-follow the original sender and anyone who replies.
  > - Let a current member follow/unfollow from the conversation screen.
  > - Deliver new reply emails only to current followers, excluding the reply author.
  > - Provide one defined, secure email stop-follow mechanism.
  > - Prove the rule through domain/integration tests and the revised `club_message_replies.feature`.
  > 
  > Do not include digesting, batching, inbound reply-by-email, custom thread folding, or broader delivery-path refactoring unless required by the chosen implementation.
  > 
  > ## Required plan edits
  > 
  > 1. Resolve the `Open Technical Decisions` section by choosing:
  >    - the follow storage/projection approach,
  >    - the unsubscribe token/authentication approach,
  >    - whether reply delivery reuses the 039 path or introduces a shared delivery helper.
  > 2. Add concrete acceptance criteria for email stop-follow behavior:
  >    - valid link,
  >    - invalid/expired/tampered link,
  >    - already-unfollowed link,
  >    - whether login is required,
  >    - success/failure user-visible outcome.
  > 3. Add follow/unfollow permission criteria:
  >    - only current members can follow/unfollow,
  >    - behavior for former/non-members,
  >    - idempotent repeated follow/unfollow behavior.
  > 4. Update the validation plan to include tests for those permission and token/error cases.
  > 
  > ## Validation plan
  > 
  > Success should be proven by:
  > 
  > - Domain tests for auto-following sender/repliers, default non-follow state, manual follow/unfollow, idempotency, and permission rejection.
  > - Delivery tests showing replies go only to current followers and exclude the reply author.
  > - Email tests for footer copy, stop-follow link generation, valid stop-follow behavior, invalid/tampered token behavior, and no further emails after unfollowing.
  > - UI/browser tests for the conversation follow/unfollow control state transitions.
  > - Acceptance scenarios in `club_message_replies.feature` covering follower-only delivery, auto-follow, opt-in default, follow/unfollow, and unfollow-stops-email.
  > - Existing 039 conversation/reply/membership scenarios remaining green, with the old reply-all audience rule superseded.
  > - `dev check` passing.
  > 
  > {"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Core technical decisions are explicitly unresolved; Email stop-follow/unsubscribe behavior is not specified enough to implement safely; Follow/unfollow permissions and edge/error states are incomplete","gemini_review_required_edits":"Resolve follow storage, unsubscribe token/authentication, and reply delivery implementation choices; Add concrete acceptance criteria for valid, invalid, expired/tampered, and repeated email stop-follow links; Add current-member permissions and idempotency criteria for follow/unfollow; Update validation plan with tests for permission and token/error cases"}}

## Stage: claude_review
- Status: succeeded
- Handler: agent
- Model: claude-sonnet-4-5
- Tokens: 4.7k in / 2.8k out
- Response:
  > I'll now analyze this plan against the readiness criteria and provide a comprehensive review.
  > 
  > ---
  > 
  > # Iteration 040 Plan Review
  > 
  > ## Decision: **READY**
  > 
  > ## Confidence: **High**
  > 
  > ---
  > 
  > ## Blocking Gaps
  > 
  > **None.**
  > 
  > ---
  > 
  > ## Non-blocking Improvements
  > 
  > 1. **Follow data model specificity:** The plan mentions "a per-(member, conversation) follow state" and "Event-sourced, consistent with `Memba.Messaging`" but doesn't specify command/event names or the projection schema. While "Open Technical Decisions" acknowledges storage choices, naming the likely commands/events (e.g., `FollowConversationRequested`, `ConversationFollowed`, `ConversationUnfollowed`) and the projection shape (e.g., `conversation_followers` table with `{conversation_id, member_id, followed_at}`) would improve implementation clarity.
  > 
  > 2. **Unsubscribe token approach hint:** While Open Technical Decisions lists "unsubscribe token mechanism," providing a slight preference or constraint (e.g., "prefer reusing existing token helpers for consistency" or "note security constraints") could guide implementation without blocking progress.
  > 
  > 3. **Auto-follow timing precision:** The plan says "auto-follow the sender on conversation creation and a replier on reply (from the 039 events)." It could be slightly clearer whether this means reacting to domain events in event handlers or inline within command handlers. However, the phrase "from the 039 events" suggests reactive event handling, which is sufficient.
  > 
  > 4. **Email quoted-thread format specifics:** The plan describes "standard quoted thread" format with `blockquote.gmail_quote` + "On <date>, <name> wrote:" attributions. While the design reference is clear, explicitly noting whether this uses Phoenix helpers or requires custom HTML generation would help implementation, though not blocking.
  > 
  > 5. **Migration mention:** No explicit mention of migrations for the follow projection/read model, though the event-sourced approach and projection language imply this. A brief mention (e.g., "add migration for follow projection table") would be thorough but isn't blocking given the clear model description.
  > 
  > ---
  > 
  > ## Smallest Viable Iteration
  > 
  > The plan **already represents the smallest viable iteration.** The scope is tightly focused on a single coherent outcome: changing reply delivery from all-members to followers-only, with the minimal follow model needed to support that change. The follow model, auto-follow behavior, opt-in control, and delivery narrowing are all interdependent and must ship together to be useful.
  > 
  > Splitting further would leave an incomplete capability:
  > - Auto-follow without delivery narrowing = no benefit
  > - Delivery narrowing without auto-follow = original sender wouldn't receive replies
  > - Follow UI without delivery change = control exists but has no effect
  > 
  > The out-of-scope boundaries are clear and appropriate (digest/batching, reply-by-email, mute-but-stay preferences).
  > 
  > ---
  > 
  > ## Required Plan Edits
  > 
  > **None.** The plan is ready for implementation as written.
  > 
  > ---
  > 
  > ## Validation Plan
  > 
  > The plan includes a comprehensive validation approach:
  > 
  > 1. **Domain/integration layer:**
  >    - Auto-follow rules (sender at creation, replier at reply)
  >    - Opt-in default (non-engaged members don't follow)
  >    - Follow/unfollow command execution
  >    - Reply delivery to followers only
  >    - Replier excluded from their own notification
  >    - Unfollow stops future delivery
  > 
  > 2. **Email delivery layer:**
  >    - Only followers receive emails
  >    - Stop-following link functionality
  >    - Footer content ("you're following · stop following")
  >    - Sender remains `<club> via Memba`
  >    - Conversation context preserved (quoted thread format)
  > 
  > 3. **Acceptance scenarios:**
  >    - `@iteration-040` scenarios in `club_message_replies.feature` pass
  >    - Existing 039 conversation/reply/membership scenarios remain green
  >    - Replace "reply emailed to every member" with "reply emailed to followers"
  > 
  > 4. **Full validation:**
  >    - `dev check` passes
  > 
  > **How to prove success:**
  > - Before: A reply emails all current members (noisy reply-all from 039)
  > - After: A reply emails only followers; sender and repliers auto-follow; others must opt in; unfollowing stops emails
  > - Evidence: BDD scenarios demonstrate the new rules; manual verification shows non-followers receive no emails
  > 
  > The validation plan is complete, concrete, and testable.
  > 
  > ---
  > 
  > ## Detailed Assessment
  > 
  > ### 1. Goal Clarity ✅
  > 
  > **Is the goal clearly articulated?**
  > Yes. The goal is explicit: "Stop emailing every reply to the whole club. Introduce following a conversation so that a reply reaches only the people who follow it."
  > 
  > **Does it state the user/business outcome?**
  > Yes. The outcome is behavioural: members can opt in to receive replies, avoiding the noisy reply-all while ensuring engaged participants (sender and repliers) still hear the conversation. The "After this iteration" section clearly articulates the four observable capabilities.
  > 
  > **Is the intended beneficiary clear?**
  > Yes. Club members are the beneficiaries: they receive fewer unwanted emails (non-followers are not spammed) while having clear opt-in control when they want to follow a conversation.
  > 
  > ### 2. Scope Focus ✅
  > 
  > **Is the scope focused on one coherent outcome?**
  > Yes. The iteration has a single, coherent outcome: changing reply delivery from "all members" to "followers only" and providing the minimal follow model to support that change.
  > 
  > **Could it be any smaller while still useful?**
  > No. The follow model (auto-follow + opt-in control + unfollow) and the delivery narrowing are interdependent and must ship together. Removing any piece would leave an incomplete or broken capability.
  > 
  > **Are non-goals and boundaries clear?**
  > Yes. Out of scope explicitly lists:
  > - Reply-by-email (iteration 041)
  > - Digest/batching
  > - Changes to who can reply
  > - Advanced notification preferences (mute-but-stay)
  > 
  > ### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅
  > 
  > **Are acceptance criteria concrete, clear, complete, and testable?**
  > Yes. The six acceptance criteria are specific and objectively verifiable:
  > 1. Auto-follow rules (sender, repliers, non-engaged defaults)
  > 2. Follow/unfollow functionality (in-app and email)
  > 3. Reply delivery to followers only
  > 4. Unfollow stops future emails
  > 5. Email infrastructure preserved (tracking, layout, sender)
  > 6. BDD scenarios pass, `dev check` passes
  > 
  > They cover happy paths (follow, reply delivery), edge cases (replier excluded from their own email), permissions (only current members), state changes (follow/unfollow), and error conditions implicitly (unfollow stops delivery = validates halting).
  > 
  > **BDD scenario classification?**
  > Yes. The plan explicitly classifies this as "Behaviour-facing" and includes an `## Acceptance Scenarios / Feature Files` section stating "BDD decision: **Required.**"
  > 
  > **Are feature files specified?**
  > Yes. The plan names `acceptance-tests/features/club_message_replies.feature` and describes exactly what changes: replace the 039 "every member" rule with "followers only," add scenarios for auto-follow, opt-in default, follow/unfollow, and unfollow-stops-email. The "Allowed acceptance feature changes" section provides precise instructions.
  > 
  > **Are business decisions resolved?**
  > Yes. The "Open Business Decisions" section states "None outstanding on audience" and explicitly documents the Reply-To decision (no-reply guidance in this iteration, conversation address in 041). The confirmed decisions (only followers, auto-follow, default off) are clear.
  > 
  > ### 4. Implementation Plan and Technical Decisions ✅
  > 
  > **Are implementation steps clear, ordered, and specific?**
  > Yes. The six-step plan is logical and sequential:
  > 1. Add follow model (commands/events/projection, auto-follow)
  > 2. Rewire delivery (all members → followers)
  > 3. Add UI control
  > 4. Add email unsubscribe link
  > 5. Revise BDD scenarios
  > 6. Run `dev check`
  > 
  > **Are likely files, modules, and integration points named?**
  > Reasonably. The plan names:
  > - `club_message_replies.feature` (BDD)
  > - `Memba.Messaging` (consistency guideline)
  > - Design assets: `emails/reply-notification.html`, `wireframes/member-conversation.html`
  > - Integration point: "iteration 038's email-handoff boundary if landed"
  > 
  > The lack of specific module names (e.g., `Memba.Messaging.FollowConversation` command) is noted as a non-blocking improvement but doesn't prevent implementation.
  > 
  > **Are data model, API, UI, workflow changes clear?**
  > Yes:
  > - **Data model:** Per-(member, conversation) follow state, event-sourced
  > - **API/domain:** Follow/unfollow commands, auto-follow on creation/reply
  > - **UI:** Follow toggle on message-detail screen
  > - **Workflow:** Reply delivery filtered to followers, unsubscribe link in email
  > - **Email:** Quoted thread format, footer with follow state
  > 
  > **Are technical decisions resolved or appropriately deferred?**
  > Yes. The "Open Technical Decisions" section lists three implementation details (follow storage approach, token mechanism, delivery path factoring) and correctly notes "these are implementation details and should not need product decisions." These are appropriate for implementation-time resolution.
  > 
  > ### 5. Expected Capability and Validation ✅
  > 
  > **What can we do after that we cannot do now?**
  > Clearly stated:
  > - Before: Replies email all members (noisy, from 039)
  > - After: Replies email only followers; members can opt in/out; sender and repliers auto-follow
  > - Net new: Model C opt-in reply delivery, eliminating reply-all noise
  > 
  > **How will we prove success?**
  > Comprehensive validation plan covering domain tests, email tests, BDD scenarios, and `dev check`.
  > 
  > **Is there a clear stop condition?**
  > Yes. The acceptance criteria and BDD scenarios provide objective pass/fail conditions. The iteration is complete when replies email followers (not all members), auto-follow works, follow/unfollow controls work, and scenarios pass.
  > 
  > ---
  > 
  > ## Summary
  > 
  > This is a **well-structured, implementation-ready plan**. The goal is clear and user-focused. The scope is minimal and coherent. Acceptance criteria are concrete and testable. BDD scenarios are properly specified with clear feature file changes. Business decisions are resolved. The implementation plan is logical and specific. Technical decisions are appropriately identified as implementation-time choices. The validation approach is thorough.
  > 
  > The plan demonstrates excellent scope discipline: it changes exactly what's needed to move from interim reply-all to opt-in followers, no more and no less. The design references and email format specifications provide clear implementation targets. The relationship to iterations 039 (builds on) and 041 (sets up for) is explicit.
  > 
  > The non-blocking improvements identified above would enhance clarity but do not prevent successful implementation. An experienced team can proceed confidently with this plan as written.
  > 
  > ---
  > 
  > ```json
  > {"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}
  > ```

## Stage: codex_review
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 7.0k in / 3.7k out
- Response:
  > ## Decision: NOT READY
  > 
  > ## Confidence: High
  > 
  > I read the complete plan file directly from `docs/iterations/040-thread-follow-and-reply-notification-emails/plan.md` lines 1–118.
  > 
  > The plan is strong and close to ready: the goal, user outcome, feature-file decision, and main behavioural rules are clear. However, two readiness gaps remain blocking because they affect security/workflow correctness for an in-scope email action and recipient authorization.
  > 
  > ## Blocking gaps
  > 
  > 1. **Reply-email stop-follow workflow/token behaviour is unresolved.**  
  >    The plan explicitly includes “stop following from a reply email,” but the unsubscribe token mechanism is still listed as an open technical decision. The acceptance criteria also do not specify whether the link is one-click, login-required, token-scoped, expiring, reusable, idempotent, or how invalid/expired/forged links behave. Because this is an email-originated state-changing action, this is a security/workflow decision that should be resolved before implementation.
  > 
  > 2. **Reply-recipient eligibility is ambiguous around membership/authorization boundaries.**  
  >    The plan says replies go to “current followers,” but it does not explicitly state that recipients must also be current club members / authorized conversation participants. Iteration 039’s rule was “all current members”; replacing that with “followers” should preserve the current-member boundary unless intentionally changed. Acceptance criteria should cover or explicitly exclude cases like a former member who still has a follow record.
  > 
  > ## Non-blocking improvements
  > 
  > 1. Resolve or reframe the other open technical decisions. Follow storage and delivery-helper factoring can probably be left to implementation if the plan explicitly says they are implementer choices and gives constraints, but leaving them under “Open Technical Decisions” weakens readiness.
  > 
  > 2. Add likely implementation touchpoints where useful: event/command modules, projections/read models, email template/module, message-detail LiveView/component, route/controller for email stop-follow, and relevant tests.
  > 
  > 3. Add explicit idempotency expectations for follow/unfollow commands: following twice and unfollowing twice should not create inconsistent state or duplicate delivery.
  > 
  > 4. Clarify whether auto-follow is derived from existing conversation/reply events, emitted as explicit follow events, or both. This matters for projections/backfills if iteration 039 conversations already exist.
  > 
  > ## Smallest viable iteration
  > 
  > The smallest useful slice is:
  > 
  > - Per-conversation follow state.
  > - Auto-follow original sender and repliers.
  > - In-app follow/unfollow control.
  > - Reply fan-out only to current club members who are currently following, excluding the reply author.
  > - Tests/acceptance coverage for the follower delivery rule.
  > 
  > The email stop-follow link can remain in this iteration only if its token/workflow/security semantics are specified. Otherwise, it should be split into a follow-up slice.
  > 
  > ## Required plan edits
  > 
  > 1. Add a concrete “Reply email stop-follow behaviour” section specifying:
  >    - Whether the link is one-click or requires sign-in.
  >    - Token scope: member + conversation + club.
  >    - Expiry/reuse policy.
  >    - Idempotent behaviour when already unfollowed.
  >    - Invalid/expired/forged token behaviour.
  >    - Whether the response leaks conversation/member existence.
  >    - Required tests.
  > 
  > 2. Clarify delivery eligibility as something like:  
  >    “A reply email is sent only to current club members who are currently following the conversation, excluding the reply author.”
  > 
  > 3. Add acceptance criteria/scenarios for the membership boundary, for example:
  >    - A former/non-current member with a previous follow state does not receive reply emails.
  >    - An invalid stop-follow link does not change follow state.
  >    - A valid stop-follow link only unfollows the intended recipient from the intended conversation.
  > 
  > 4. Update `Open Technical Decisions` so that blocking decisions are either resolved or explicitly delegated with safe constraints. At minimum, resolve the unsubscribe token/workflow decision before implementation starts.
  > 
  > ## Validation plan
  > 
  > To prove the iteration succeeded:
  > 
  > 1. Domain/integration tests cover:
  >    - Original sender auto-follows.
  >    - Replier auto-follows.
  >    - Non-engaged current member is not following by default.
  >    - Member can follow and unfollow.
  >    - Follow/unfollow is idempotent.
  >    - Replies are emailed only to current club-member followers.
  >    - Reply author is excluded.
  >    - Former/non-current members do not receive emails.
  >    - Unfollow stops future emails.
  > 
  > 2. Email/security tests cover:
  >    - Reply email contains the correct follow status/footer and stop-follow link.
  >    - Valid stop-follow link changes only the intended member/conversation state.
  >    - Already-unfollowed link is safe/idempotent.
  >    - Invalid/expired/forged links do not change state.
  >    - Existing delivery tracking, layout/footer, and `<club name> via Memba` sender remain intact.
  > 
  > 3. Acceptance:
  >    - Revised `acceptance-tests/features/club_message_replies.feature` scenarios tagged for iteration 040 pass with temporary todo tags removed or narrowed.
  >    - Preserved 039 conversation/reply/membership scenarios remain green, except for the superseded reply-audience rule.
  > 
  > 4. Final stop condition:
  >    - All relevant tests pass.
  >    - `dev check` passes.
  > 
  > {"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Reply-email stop-follow workflow/token behaviour is unresolved; Reply-recipient eligibility around current club membership/authorization is ambiguous","codex_review_required_edits":"Specify stop-follow link token/workflow/security/idempotency/error behaviour and tests; Clarify delivery only to current club-member followers excluding author and add membership-boundary acceptance coverage"}}

## Current context
| Key | Value |
|-----|-------|
| claude_review_blocking_gap_count | 0 |
| claude_review_blocking_gaps | None |
| claude_review_confidence | High |
| claude_review_decision | READY |
| claude_review_required_edits | None |
| codex_review_blocking_gap_count | 2 |
| codex_review_blocking_gaps | Reply-email stop-follow workflow/token behaviour is unresolved; Reply-recipient eligibility around current club membership/authorization is ambiguous |
| codex_review_confidence | High |
| codex_review_decision | NOT READY |
| codex_review_required_edits | Specify stop-follow link token/workflow/security/idempotency/error behaviour and tests; Clarify delivery only to current club-member followers excluding author and add membership-boundary acceptance coverage |
| gemini_review_blocking_gap_count | 3 |
| gemini_review_blocking_gaps | Core technical decisions are explicitly unresolved; Email stop-follow/unsubscribe behavior is not specified enough to implement safely; Follow/unfollow permissions and edge/error states are incomplete |
| gemini_review_confidence | High |
| gemini_review_decision | NOT READY |
| gemini_review_required_edits | Resolve follow storage, unsubscribe token/authentication, and reply delivery implementation choices; Add concrete acceptance criteria for valid, invalid, expired/tampered, and repeated email stop-follow links; Add current-member permissions and idempotency criteria for follow/unfollow; Update validation plan with tests for permission and token/error cases |


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
