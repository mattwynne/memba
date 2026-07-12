## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the wording around sign-in with a pending known address. The acceptance criteria say it “may verify” the address, while the scenario summaries and validation plan say it verifies the address. Prefer “does verify” if that is the intended rule.
2. Specify the intended token expiry/one-use policy more concretely if the project wants deterministic validation beyond “invalid/expired” handling.
3. Name the likely domain/context modules and migration locations if known, to reduce implementation discovery time.
4. Add an explicit expected behavior for unauthenticated access to `/my/settings`, such as redirecting to sign-in.
5. Consider adding explicit criteria for duplicate normalized email addresses already attached to the same Person, not only another Person.

## Smallest viable iteration

The smallest useful slice is: add verified/pending state for Person email addresses, backfill existing rows as verified, add `/my/settings` for signed-in People, allow members to add a pending email address, send/consume a verification link, and prevent pending addresses from becoming primary or being used for inbound identity. Primary switching, removal, resend, and live-refresh are valuable but could be follow-up slices if implementation risk needs to be reduced.

That said, the current plan is still coherent as one behaviour-facing iteration because all included work supports the single outcome: members can safely manage their own verified email addresses.

## Required plan edits

None required for readiness.

## Validation plan

Success should be proven by:

1. Domain/context tests covering:
   - existing addresses backfilled as verified;
   - newly added addresses becoming pending;
   - pending addresses blocked from primary delivery and inbound identity;
   - verification link success;
   - old/removed/replaced link rejection;
   - duplicate normalized address rejection;
   - primary removal prevention;
   - sign-in-link verification for pending known addresses.

2. LiveView/controller tests covering:
   - avatar menu link and separator;
   - `/my/settings` visibility for signed-in People;
   - Person basics, memberships, and email-address rows;
   - add, resend, remove, and make-primary flows;
   - verification success and invalid/expired pages;
   - PubSub/live refresh after verification.

3. Acceptance coverage in `acceptance-tests/features/person_email_addresses.feature` for the listed `@iteration-053` scenarios, with temporary `@todo-domain` / `@todo-ui` tags removed or narrowed as behavior becomes executable.

4. Full project validation with `dev check`.

5. Manual demo confirming:
   - member opens Account settings;
   - adds a pending email;
   - cannot make it primary before verification;
   - verifies via emailed link;
   - settings page updates;
   - verified address can become primary;
   - old non-primary address can be removed;
   - future club-message delivery uses the new verified primary address.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}