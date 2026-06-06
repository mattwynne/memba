## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/024-email-template-designs/plan.md` before reviewing.

## Blocking gaps

1. **The plan still contains unresolved technical/output decisions that affect implementation and acceptance.** The `## Open Technical Decisions` section leaves open whether member-message plain text stays exactly unchanged or gains a footer, how much group context sign-in emails receive, and whether configured sender addresses should align with the design spec or remain untouched. These affect user-visible email content, template variants, and test expectations.

2. **A support-copy/business decision is still unresolved.** The risks section says publishing `help@memba.io` may require confirming that the mailbox/support process exists before using it literally. Because the scope mentions key trust/support copy, the plan should decide whether that address is approved, replaced, or omitted.

## Non-blocking improvements

1. Name the existing acceptance feature files/scenarios that may need assertion updates, even if no new Gherkin is required. The rationale for not adding new Gherkin is acceptable, but naming the existing coverage would make validation clearer.

2. Identify likely test files in addition to modules, especially for auth emails, onboarding welcome emails, member-message delivery providers, and inbound rejection emails.

3. Clarify what counts as “compatible v2 sign-in/welcome pattern” for onboarding welcome email so implementers know which source artifact or variant to follow.

4. Define the expected manual preview stop condition more concretely, such as “all four email types inspected in local mailbox at desktop and narrow/mobile widths with fallback URLs visible.”

## Smallest viable iteration

The smallest useful slice would be: **implement the shared v2 transactional email shell plus sign-in-link and onboarding-welcome emails only**, preserving plain-text fallback URLs and auth behaviour. That would deliver a coherent, high-value member-facing improvement while avoiding the separate member-message and inbound-rejection copy/threading concerns.

However, the current full scope can still be viable once the unresolved decisions are closed because all email types belong to one coherent transactional email design-system outcome.

## Required plan edits

1. Resolve the `## Open Technical Decisions` section before implementation:
   - Choose the helper/module structure, or explicitly mark it as implementer discretion.
   - Decide whether member-message plain text remains exactly the sender’s body or may include a footer.
   - Define when sign-in emails are club/group-led and what the fallback is when group context is unavailable.
   - State that configured sender addresses/domains remain unchanged unless this iteration explicitly updates display names only.

2. Confirm whether `help@memba.io` is approved for template copy, or replace it with approved support/contact wording.

3. Update acceptance criteria to reflect the final decisions, especially member-message plain text behaviour, sign-in context behaviour, and sender-address/display-name policy.

## Validation plan

Success should be proven by:

1. Unit tests covering:
   - sign-in email HTML/text, fallback URL, expiry/one-use reassurance, and context-specific heading/subject;
   - onboarding welcome email HTML/text and group-led content;
   - member-message HTML/text, From, Reply-To, subject, metadata, and local delivery fact recording;
   - inbound rejection HTML/text, reason mappings, subject, threading headers, and provider metadata/tags;
   - escaping of user-, sender-, message-, and group-provided content.

2. Manual local mailbox previews for:
   - sign-in link;
   - onboarding welcome link;
   - member message;
   - inbound rejection notice.

3. Comparison against the v2 source artifacts for structure, copy hierarchy, and conservative email-client-safe HTML.

4. `dev check` passing before completion.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Open technical/output decisions affect member-message text body, sign-in context variants, and sender address policy; Support-copy decision for help@memba.io is unresolved","codex_review_required_edits":"Resolve or reclassify open technical decisions with explicit defaults; Confirm or replace help@memba.io support copy; Update acceptance criteria to reflect final decisions"}}