# Problems

## Check email page should update after sign-in in another browser

Observed: 2026-06-06

When someone is waiting on `auth/check_email` and completes sign-in in another browser, the check email page does not automatically reflect that the sign-in has happened.

Expected:

- The check email page updates when the sign-in is completed elsewhere.
- The user is not left waiting on stale instructions after they have already signed in.
