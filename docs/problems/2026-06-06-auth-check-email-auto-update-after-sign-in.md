# Problems

## Check email page should update after sign-in in another browser

Observed: 2026-06-06

Status: Unresolved. [Iteration 023](../iterations/023-copy-review-for-older-club-members/plan.md) improved the check-email page copy, but did not add cross-browser/session-live update behaviour.

When someone is waiting on `auth/check_email` and completes sign-in in another browser, the check email page does not automatically reflect that the sign-in has happened.

Expected:

- The check email page updates when the sign-in is completed elsewhere.
- The user is not left waiting on stale instructions after they have already signed in.
