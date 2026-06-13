## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The implementation plan could name likely concrete modules/files once confirmed, such as the auth controller/LiveView, Postmark webhook controller, mailer/auth email builder, migration, context module, and LiveView test files.
2. The legacy `/auth/check-email` behaviour is slightly flexible: “renders existing static neutral guidance or redirects to the sign-in form.” Either is acceptable, but choosing one in the plan would reduce implementation discretion.
3. The cleanup mechanism for 7-day retention is described as “eligible for cleanup” but not assigned to a job/task. This is acceptable for readiness, but implementation should decide whether cleanup is part of this iteration or a follow-up operational task.
4. The acceptance scenarios list only two shared Cucumber scenarios. That is probably enough for stakeholder-readable coverage, while lower-level tests cover webhook edge cases, but the author could note that edge cases remain unit/controller/LiveView test coverage rather than Gherkin.

## Smallest viable iteration

The smallest useful slice is:

- Create an opaque auth-email request/progress record for every submitted address.
- Preserve anti-enumeration behaviour for known and unknown emails.
- Send known auth emails with Postmark metadata that correlates to the request.
- Show a LiveView check-email progress page by opaque request ID.
- Update the page live when a Postmark delivered/provider-accepted webhook is received.
- Show neutral fallback copy after 60 seconds and avoid fake provider-accepted states for unknown emails.
- Prove existing sign-in behaviour still works.

Delayed/bounced/spam-complaint diagnostics, duplicate idempotency, expiry, and retention should still be implemented or safely handled as planned, but the core user value is provider-accepted progress without account enumeration.

## Required plan edits

None required before implementation.

## Validation plan

To prove the iteration succeeded:

1. Add/update acceptance scenarios in `acceptance-tests/features/authentication.feature` for:
   - A known user seeing provider-accepted progress.
   - An unknown email receiving the same neutral waiting experience without account disclosure.
2. Run targeted persistence/context tests proving auth-email request creation, expiry, status transitions, and retention eligibility.
3. Run auth email construction tests proving known recipients receive Postmark metadata that correlates to the opaque auth-email request and uses the auth stream.
4. Run webhook controller tests for delivered/provider-accepted, delayed, bounced, spam complaint, malformed, duplicate, and missing-correlation events.
5. Run LiveView tests proving neutral initial state, fallback after 60 seconds, live update after committed provider acceptance, expired guidance after 30 minutes, and privacy-preserving copy for unknown addresses.
6. Run existing sign-in-link tests to confirm known users can still sign in, unknown users cannot, and tokens remain one-use and expiring.
7. Run the updated Cucumber scenarios once implementation support exists and remove/narrow the todo tags when passing.
8. Run `dev check` before completion.
9. Optionally perform the planned staging/production smoke test with a controlled known address and controlled unknown address.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}