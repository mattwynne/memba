# Problems

## Onboarding requests can be submitted with unvalidated email addresses

Observed: 2026-06-08

Status: Resolved by [iteration 030: Verified onboarding requests](../iterations/030-verified-onboarding-requests/plan.md). Signed-out public requesters must verify control of their email address through the sign-in link flow before submitting a Staff-reviewable onboarding request. Email-only verification attempts do not create onboarding request records or Staff notifications.

A person can submit a Memba access request with an email address that has not been verified. Staff may then be asked to review or act on a request without knowing whether the requester controls the supplied email address.

Expected:

- Memba should verify that the requester controls the email address before treating the request as trusted or actionable.
- The requester should have a clear path to confirm their identity, such as creating an account/person through a magic-link email before or during the request flow.
