# Public copy pass for older club members

Date: 2026-06-06
Status: draft

## Goal

Make Memba's public and member-facing copy clearer, safer, and more trustworthy for an older club member using an iPad, using the core persona of an 80-year-old mountaineer.

After this iteration, a reader should quickly understand what Memba does today, what happens when they tap a CTA, how to sign in, and whether sending a message will email everyone in the club.

## Background / Context

Matt asked to copy in marketing/copywriting skills and use them to review the site's copy. The relevant skills were added in commit `64c190a8`.

The copy audit for this iteration is captured in `copy-audit.md`. It reviewed public and member-facing user surfaces:

- logged-out homepage;
- signed-in club/memberships homepage;
- about;
- get-started request flow and acknowledgement;
- sign-in and check-email;
- public club page;
- member club home/dashboard;
- member message compose, success, and error states;
- member message detail and delivery status page;
- terms and privacy;
- shared public/club layout navigation and reconnect/error copy.

The current copy is warm and calm, but some wording is too abstract, too future-facing, or too technical for the older iPad persona. The most important risks are trust breaks from overclaiming future features, unclear CTAs, and insufficient consequence-setting before emailing all members.

## Scope

### In scope

- Rewrite logged-out homepage hero, CTAs, and feature-card copy so it describes Memba's current public/member-message capability rather than future roadmap capabilities.
- Rewrite `/get-started` copy and form microcopy around staff-reviewed setup, with warmer next-step reassurance.
- Rewrite sign-in and check-email copy to explain magic-link sign-in in older-reader-friendly language.
- Rewrite the public club page copy and CTA so members know to use the email address their club has for them.
- Rewrite member club home/dashboard copy for clarity and consequence-setting.
- Rewrite member compose copy, placeholders, success copy, and error copy so it is clear that the message goes to all current members and what happens after sending.
- Rewrite member message detail delivery-status copy to avoid confusing terms such as "receipt groups", "addressed members", and "projected" in member-facing UI.
- Make small plain-language trust improvements to privacy/terms copy if they can be done without needing legal-policy decisions.
- Keep existing routes, workflows, permissions, and page structure unless a tiny label/help-text adjustment is needed for clarity.
- Add/update tests only where existing tests assert changed visible copy or button labels.
- Run a manual copy review on an iPad-sized viewport, or document why it could not be run.
- Keep `dev check` green.

### Out of scope

- Adding new product capabilities.
- Changing signup/onboarding policy beyond copy.
- Changing message-sending authorization or recipient rules.
- Adding testimonials, customer logos, claims, statistics, or proof not already available.
- Full legal review or legally substantive terms/privacy changes.
- Full visual redesign, typography/accessibility redesign, or responsive layout work except where copy length forces minor wrapping fixes.
- Staff/admin operations copy.
- A/B testing infrastructure.
- Search-engine/content strategy work beyond page titles/meta copy if the implementation finds obvious low-risk improvements.

## Iteration Type

Behaviour-facing copy/content iteration.

The underlying product rules do not change, but user-observable page content changes across public and member-facing pages. The user-observable rule that must remain clear is especially important on the compose page: sending a club message sends it to all current members.

## Acceptance Scenarios / Feature Files

BDD decision: Useful but not required.

This slice changes wording and clarity rather than business rules. Existing acceptance scenarios already cover the important behaviours: authentication, club pages, member dashboard, member message sending, and delivery views. New Gherkin would mostly assert editorial text and would be brittle.

No shared Cucumber feature files are expected to change. If implementation changes any user-facing labels that existing scenarios rely on, update the relevant existing scenarios or step text only to preserve the same behaviour coverage.

## Acceptance Criteria

- Homepage copy states the current Memba value proposition without promising unavailable renewals or event management.
- Homepage primary CTA tells visitors the concrete next action, such as requesting access for their club.
- Homepage secondary CTA accurately describes where it goes.
- `/get-started` explains that Memba reviews each club request before setup.
- `/get-started` form labels and placeholders ask plain, concrete questions.
- `/get-started` acknowledgement says what happens next and that no club/access has been created yet.
- `/auth` tells members to use the email address their club has for them.
- `/auth` privacy microcopy explains neutral responses without sounding alarming.
- `/auth/check-email` tells the user to open the email and tap the sign-in link/button, and explains expiry in plain language.
- Public club page copy tells members what they can do after sign-in and that member-only details stay private.
- Public club page CTA says what sign-in action will happen.
- Signed-in memberships empty state tells users what to try next if no clubs are found.
- Member dashboard hero copy plainly lists the main jobs: read messages, send a note, see current members.
- Member dashboard send-message area states that club-wide messages go to all current members.
- Member compose page clearly warns before submission that the message will be sent to all current members of the selected club.
- Member compose subject/body placeholders are concrete and useful to an older club member.
- Member compose success copy says the message is being sent and points to delivery details without using metaphorical language.
- Member compose error copy says whether anyone received the message and gives a practical next step.
- Member message detail page uses "delivery" language rather than potentially confusing "receipt" language where visible to members.
- Member delivery status empty states avoid internal terms like "projected".
- Terms/privacy copy remains concise, plain, and not more legally ambitious than the current policy unless Matt explicitly approves new policy language.
- Existing tests that rely on visible labels/copy are updated without weakening behaviour coverage.
- A manual review at iPad-like width confirms the revised copy remains readable and buttons/labels still make sense.
- `dev check` passes.

## Open Business Decisions

- Whether Memba should use Canadian/Commonwealth spelling consistently (for example, "organiser"/"organisation") or North American spelling ("organizer"/"organization"). Current copy appears mixed.
- Whether to publish a direct Memba contact address such as `hello@memba.io` on privacy/terms and error/help copy, rather than routing people through `donkey.red`.
- Whether homepage copy should position Memba around today's strongest capability (private member messaging) or the broader near-term product category (membership software for volunteer-run clubs) while avoiding unavailable-feature claims.
- Whether legal/privacy copy can add plain-language statements about club control of member records and email-provider use without formal legal review.

## Implementation Plan

1. Re-read `copy-audit.md`, the public templates, member-facing LiveViews/templates, and presentation helpers that produce member-visible delivery status text.
2. Inventory existing tests and acceptance scenarios that assert visible copy, button labels, placeholders, or page headings on public/member pages.
3. Draft replacement copy for each page using the audit's older-iPad persona principles:
   - plain words;
   - concrete next steps;
   - clear consequences before sending;
   - no unsupported claims;
   - no internal technical terms in member-facing UI.
4. Apply copy edits to the relevant Phoenix templates/LiveViews and presentation helpers.
5. Keep layout and route structure unchanged unless a label or help-text edit requires a small markup adjustment.
6. Update tests that assert the old copy while preserving behaviour intent.
7. Run targeted Phoenix tests and browser acceptance tests touched by changed labels.
8. Review pages manually at an iPad-like viewport:
   - logged-out homepage;
   - get-started request form and acknowledgement;
   - sign-in/check-email;
   - public club page;
   - member dashboard;
   - compose message and success/error states if practical;
   - message detail delivery view.
9. Run `dev check` and fix any failures.
10. Record implementation notes and any unresolved copy decisions in the iteration folder.

## Open Technical Decisions

None expected. Implementation should inspect whether visible delivery status descriptions live in templates or presentation modules and edit the right source of truth.

## New Capability

Memba will speak more clearly to older club members and volunteer organisers: users can understand the current product, sign in with less uncertainty, request access with clearer expectations, and send club-wide messages with clearer confidence about who will receive them.

## Validation Plan

- Code review focused on the `copy-audit.md` findings and acceptance criteria above.
- Test review for changed labels/copy so tests continue asserting behaviour rather than brittle prose where possible.
- Manual iPad-width review of the public/member pages listed in the implementation plan.
- `dev check` before completion.

## Risks / Follow-ups

- Copy changes can accidentally desynchronise with acceptance tests that use visible labels. Update tests deliberately and preserve behaviour coverage.
- Without real customer interviews, the 80-year-old mountaineer persona is an informed design lens rather than validated voice-of-customer data.
- If homepage copy narrows too far to current messaging capability, it may understate the broader membership-product ambition; if it stays too broad, it may overpromise. Matt should choose the positioning in the open business decisions.
- Legal/privacy improvements may need separate review before publishing stronger policy language.
- A later accessibility iteration should review font size, contrast, hit targets, and iPad ergonomics beyond copy alone.
