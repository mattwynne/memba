Now I'll review this plan systematically against the readiness criteria.

---

# Iteration Plan Review: Transactional Email Template Redesign

## Decision: **NOT READY**

## Confidence: **High**

## Blocking Gaps

1. **Open technical decision affects implementation path**: Whether to introduce `Memba.EmailTemplates` vs keeping helpers beside each email module is a core architectural decision that impacts the first half of the implementation plan (steps 2–3). The plan cannot execute step 2 ("Decide the maintainable implementation shape") as written because that decision should be made during planning, not during implementation.

2. **Open technical decision affects acceptance criteria**: Whether plain-text member-message bodies remain unchanged or gain a footer cannot be deferred—the acceptance criteria explicitly state "Member-message text body remains the sender's original message body, or otherwise remains safe" but the "or otherwise" path is unresolved. The plan must decide which approach is expected.

3. **Open technical decision affects scope and API changes**: How much club/group context can be passed into sign-in emails is unresolved, but the acceptance criteria require "club/member context leads with the group name where available." The plan needs to decide whether existing sign-in call sites already provide enough context, or whether API changes are required (and if so, which ones).

4. **Missing file/module naming**: The implementation plan says "per-email modules/functions" but does not name them. Are these new modules, or edits to the existing modules listed in Background? Step 3 mentions "safe HTML helpers" but doesn't say where they live or what they're called.

5. **Acceptance criteria lack edge-case coverage**: The criteria do not address what happens when:
   - A member message contains HTML or script injection attempts in the message body
   - A rejection notice lacks a known group (the criterion says "when known" but doesn't specify the fallback)
   - A sign-in link has no club context available (criterion says "where available" but doesn't define the Memba-led fallback structure)
   - Email subject lines or group names contain special characters that might break email headers

6. **Validation plan lacks specific success metrics**: The plan says "compare generated emails against v2 source artifacts" but doesn't define what "matching" means—exact visual match? Same semantic structure? Same trust marks and buttons present? Without clearer criteria, the validation step is subjective.

## Non-blocking Improvements

1. **Implementation step ordering**: Step 11 says "Run any affected acceptance tests if mailbox text parsing changes," but the plan states in the Acceptance Scenarios section that existing scenarios won't change their behaviour coverage. This is mildly inconsistent—either the plan should proactively identify which scenarios parse mailbox text and plan to update them (step 11 becomes non-conditional), or state that no scenario updates are expected.

2. **Risk about help@memba.io is actionable now**: The plan lists confirming the help@memba.io mailbox as a risk/follow-up, but it could be a quick pre-implementation check. If the mailbox doesn't exist, the copy should change during planning, not as a discovered mid-implementation issue.

3. **Missing test file names**: Implementation step 9 lists test updates but doesn't name the test files (e.g., `test/memba/accounts/auth_email_test.exs`). Adding file paths would make the plan more concrete.

4. **"Useful but not required" BDD decision could be clearer**: The plan says existing scenarios exercise the behaviour already, but then says "if existing scenarios assert old email text, update them." It would be clearer to either name the specific scenarios that need updates, or state "no scenario updates expected" more definitively.

## Smallest Viable Iteration

The plan is already quite focused. A smaller slice could be:

**Sign-in links only**: Implement the v2 sign-in template for `Memba.Accounts.AuthEmail`, preserving plain-text bodies and context-appropriate subjects. Defer member messages, inbound rejection, and onboarding welcome to a follow-up iteration.

This would prove out the HTML template infrastructure and safety helpers while delivering immediate user value (sign-in emails are likely the most frequently seen). The remaining email types could follow in iteration 025 using the same infrastructure.

However, the current scope is reasonable if the blocking decisions are resolved during planning.

## Required Plan Edits

1. **Resolve or remove the open technical decisions** before marking the plan ready:
   - **Module structure**: Either choose `Memba.EmailTemplates` or inline helpers now, or defer the entire iteration until this is decided externally. If the choice is genuinely implementation-time flexibility, rewrite step 2 to say "implement shared helpers in `Memba.EmailTemplates` or inline in each email module as maintainability suggests" and ensure the acceptance criteria don't depend on which path is chosen.
   - **Plain-text footer for member messages**: Decide whether member-message text bodies remain exactly the sender's original body, or may add a short reply-guidance footer. Update the acceptance criterion accordingly.
   - **Club/group context for sign-in**: Decide whether existing call sites to `AuthEmail` and `WelcomeEmail` already provide club/member context, or whether API additions are required. If API additions are required, name them in the implementation plan.
   - **From addresses**: Decide whether the implementation will change configured `from` addresses or only change display names/copy. If changing addresses, add acceptance criteria for the new address format.

2. **Add missing edge cases to acceptance criteria**:
   - "Member-message HTML escapes the sender's message body to prevent HTML/script injection."
   - "Inbound rejection notices that lack a known group use a Memba-led subject line without group name, e.g. 'Your email wasn't posted'."
   - "Sign-in links that lack club context use a Memba-led subject and heading, e.g. 'Sign in to Memba' or 'Your sign-in link'."
   - "Email subjects, group names, and sender names are header-safe encoded (no unescaped newlines or control characters)."

3. **Add implementation file names** to steps 2–9:
   - Name the helper module (e.g., `lib/memba/email_templates.ex` or similar).
   - Name the test files being updated (e.g., `test/memba/accounts/auth_email_test.exs`, `test/memba/messaging/email_delivery_providers/postmark_test.exs`, `test/memba/onboarding/welcome_email_test.exs`, `test/memba/messaging/inbound_club_rejection_email_test.exs`).

4. **Clarify validation success criteria**: Replace "Compare generated emails against the v2 source artifacts" with specific checks:
   - "Sign-in email HTML includes a primary button with href, a printed fallback URL, an expiry/one-use line, and the Memba trust mark."
   - "Member-message HTML includes group-led header, sender line, escaped message body, reply guidance, and Memba footer."
   - "Inbound rejection HTML includes Memba-led header, group name if known, one reason line, next steps, and 'nothing was posted' reassurance."

5. **Resolve the help@memba.io mailbox question** before implementation, or replace it with a placeholder (e.g., `support@memba.io`) if the real address is uncertain.

## Validation Plan

**How to prove the iteration succeeded:**

1. **Visual/content validation**:
   - Use `dev server` and trigger each email type in the local Swoosh mailbox.
   - Open the HTML preview in a browser at desktop and mobile widths.
   - Confirm each template matches the structural and copy requirements from acceptance criteria.
   - Inspect the plain-text twin for each email type and confirm it is readable and includes key information.

2. **Test validation**:
   - `mix test` passes with updated email content assertions.
   - `dev check` passes (includes tests, credo, dialyzer, format).

3. **Deliverability validation** (manual spot-check):
   - Confirm HTML email structure uses tables, inline styles, and conservative HTML (no external CSS, no modern flexbox/grid, no JavaScript).
   - Confirm HTML escaping is applied to user-provided content (group names, sender names, message bodies).
   - Confirm plain-text bodies remain simple and readable.

4. **Behaviour preservation**:
   - Sign-in links still authenticate successfully (existing acceptance scenarios pass).
   - Member-message replies still go to the sender (existing `Reply-To` tests pass).
   - Inbound rejection notices still include threading headers (existing metadata/tag tests pass).

**Stop condition**: All acceptance criteria are met, `dev check` is green, and all four email types (sign-in, member-message, inbound rejection, onboarding welcome) render visually consistent v2 templates in the local mailbox.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":6,"claude_review_blocking_gaps":"Open tech decision on module structure blocks implementation step 2; Open tech decision on plain-text footer blocks acceptance criteria; Open tech decision on club context blocks API and scope; Missing file/module names in implementation plan; Acceptance criteria lack edge-case coverage for injection, missing group, missing club context, and header encoding; Validation plan lacks specific success metrics for template matching","claude_review_required_edits":"Resolve all open technical decisions or defer iteration; Add edge cases to acceptance criteria for HTML escaping, missing group/club context, and header safety; Add specific file/module names to implementation steps 2-9; Clarify validation success criteria with concrete structural checks; Resolve help@memba.io mailbox question before implementation"}}
```