## Decision: NOT READY

## Confidence: High

I read the complete plan directly from `docs/iterations/028-staff-member-invitations/plan.md` lines 1–187.

## Blocking gaps

1. **Invitation token/profile-completion lifecycle is not fully decided.**  
   The plan says invitation links are “one-use”, that unknown invitees must enter a name before membership starts, and that leaving before entering a name must not create membership. However, it does not clearly decide whether the invitation token is consumed on first link open, on final profile completion, or whether an invitee who leaves before entering their name can return via the same link. This is a key workflow and security decision.

2. **Material technical decisions remain explicitly open.**  
   The plan’s `## Open Technical Decisions` section leaves unresolved several implementation-shaping choices, especially token storage/reuse vs separate invitation token storage, representation of invited unknown emails before a person exists, and how the generalized profile-completion gate records required details. These affect data model, auth/session flow, and domain invariants, so the plan is not yet implementation-ready.

## Non-blocking improvements

1. Add an explicit invalid/malformed invitation token acceptance criterion, even if the expected behavior is simply a safe error page or redirect with no state change.
2. Name likely route/module candidates if known, while still allowing implementation flexibility.
3. Add a brief note about database/domain uniqueness guarantees for “one pending invitation per normalized club/email” and “one active membership per person/club.”
4. Define the minimum Staff-facing copy expectations for active-member duplicate and pending-invitation resend messages.

## Smallest viable iteration

The smallest useful slice is:

- Staff invite an unknown email to a club.
- A pending invitation is created without active person or membership.
- The invitee follows the email link, enters a non-blank name, and only then becomes an active ordinary member.
- Duplicate active-member invites are blocked.
- Duplicate pending invites resend without creating another pending record.
- Direct Staff club-member creation from name/email is decommissioned.

Existing complete-person acceptance could remain in this iteration if needed for real-world usefulness, but the core pattern is the unknown-email invitation plus profile completion lifecycle.

## Required plan edits

1. Decide and document the invitation token lifecycle:
   - when the token is consumed;
   - what “one-use” means before profile completion;
   - whether an invitee who leaves before entering their name can resume via the same link;
   - when the invitation state changes from pending to accepted.

2. Resolve or constrain the open technical decisions that affect architecture:
   - token storage/reuse strategy;
   - pending invitation vs incomplete person representation;
   - profile-completion gate state model;
   - acceptance/profile route ownership at a high level.

3. Add or update acceptance criteria/scenarios for the abandoned profile-completion case to state the expected resume/retry behavior.

## Validation plan

Success should be proven by:

1. New Cucumber scenarios in `acceptance-tests/features/club_member_invitations.feature` covering the Staff invite flow, unknown invitee profile completion, existing-person acceptance, direct-creation bypass prevention, duplicate active member, duplicate pending resend, and accepted-link reuse.
2. Domain/application tests for invitation creation, normalized-email duplicate handling, token consumption semantics, abandoned profile completion, accepted invitation reuse, and no duplicate memberships.
3. Web tests for the Staff invite form, email/link generation, invitation callback, profile-completion page, redirects, and relevant error states.
4. Regression tests confirming existing staff onboarding, member sign-in, and club navigation still work.
5. `dev check` passing.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Invitation token/profile-completion lifecycle is not fully decided; Material technical decisions remain explicitly open","codex_review_required_edits":"Decide token consumption/resume semantics; Resolve or constrain token storage, pending/incomplete identity representation, and profile-completion gate model; Add acceptance criteria for abandoned profile-completion retry/resume behavior"}}