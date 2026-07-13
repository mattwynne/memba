## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/053-my-settings-email-addresses/plan.md` through line 251.

## Blocking gaps

1. **The plan still contains explicit open technical decisions that affect implementation architecture and invariants.**  
   The `## Open Technical Decisions` section leaves unresolved:
   - verification-token storage mechanism;
   - command/event shape for individual self-service email actions vs full replacement;
   - whether verification state is aggregate-enforced or projection-only;
   - PubSub topic/message shape.

   These are not just naming details; they affect migration shape, event replay, invariant enforcement, callback safety, and LiveView refresh design.

2. **The sign-in-as-verification rule is not stated consistently/objectively in the acceptance criteria.**  
   The plan alternates between “may verify” and “verifies”:
   - Scope says opening a sign-in link to a pending known address “may itself verify” the address.
   - Scenario summary says “Signing in with a pending known address verifies it.”
   - Acceptance criteria says “may verify.”
   - Validation plan says “sign-in with pending known address verifies it.”

   Acceptance criteria should be deterministic and testable.

3. **The plan status still says `needs-revision`.**  
   Even if most content is close, the file itself is not marked as ready/validated and still signals that revision is required.

## Non-blocking improvements

1. The iteration is coherent but large. It combines schema changes, domain policy, token/email infrastructure, sign-in callback changes, inbound identity changes, staff-edit compatibility, a new LiveView, avatar-menu navigation, URL-addressable tabs, PubSub refresh, and acceptance tests. Consider splitting if delivery risk is high.

2. Acceptance criteria could explicitly cover same-Person duplicate normalized addresses, not only duplicates owned by another Person.

3. The invalid/expired verification state is described as “calm” but not with exact copy. This is probably acceptable, but exact copy would make UI validation simpler.

4. The permissions boundary for `/my/settings` could be more explicit about expected redirect/error behavior for signed-out users and get-started-only identities.

## Smallest viable iteration

The smallest useful slice would be:

- add verified/pending state and backfill existing addresses as verified;
- allow signed-in members with a Membership Person to view `/my/settings/emails`;
- add a pending email address;
- send and consume a verification link;
- prevent pending addresses from becoming primary or being used for inbound identity;
- allow verified non-primary addresses to become primary;
- prevent primary removal.

Profile/Clubs tabs, live PubSub refresh, staff-edit refinements, and avatar-menu polish could be follow-up if the team needs a smaller implementation slice, though the current plan does keep them under one coherent “member account settings” outcome.

## Required plan edits

1. Resolve or convert the `## Open Technical Decisions` section into explicit implementation decisions/constraints, especially:
   - token storage approach;
   - aggregate vs projection invariant enforcement;
   - command/event strategy for add/verify/make-primary/remove/resend;
   - PubSub topic/message shape.

2. Replace the ambiguous sign-in criterion with deterministic wording, for example:  
   `Opening a valid sign-in link sent to a pending known Person email address verifies that address without making it primary or changing the Person session semantics.`

3. Update the status from `needs-revision` once the above edits are made.

## Validation plan

Success should be proven by:

- migration/domain tests showing existing rows are verified, new rows are pending, pending rows cannot become primary, verified alternates can become primary, primary rows cannot be removed, and removed pending rows cannot be verified by old links;
- token/callback tests for valid, expired, invalid, removed, and replaced-address verification links;
- sign-in tests proving pending known addresses become verified only after mailbox-control proof;
- inbound sender-resolution tests proving pending/unverified known addresses are rejected;
- LiveView/controller tests for avatar navigation, `/my/settings` rendering, URL-addressable Profile/Clubs/Emails tabs, add/resend/remove/make-primary flows, verification result pages, and live refresh;
- updated acceptance scenarios in `acceptance-tests/features/person_email_addresses.feature`;
- `dev check` passing after implementation.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Open technical decisions affect architecture and invariants; Sign-in-as-verification rule is ambiguous between may verify and verifies; Plan status still says needs-revision","gemini_review_required_edits":"Resolve token storage, command/event, aggregate/projection, and PubSub decisions; Make sign-in-as-verification acceptance criterion deterministic; Update status from needs-revision after edits"}}