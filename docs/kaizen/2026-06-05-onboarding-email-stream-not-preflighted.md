# Problem: Onboarding email stream was not preflighted before production signup test

Date: 2026-06-05

## Context

Matt was manually testing the new onboarding iteration in production. The public get-started form recorded an onboarding request and should have notified Memba staff by email.

Relevant workflow steps:

- Production deployment had already run the onboarding request migration.
- Matt submitted the public onboarding request form.
- We inspected production logs with `flyctl logs --app memba --no-tail`.
- We then used the Postmark API to inspect and create message streams on the production `memba.io` server and the dev `memba local dev` server.

## Expected standard

Before a deployed feature sends through a named external provider resource, the target production and dev provider configuration should already exist or a preflight should make the missing resource obvious before manual product testing.

For this feature, the expected Postmark Transactional Message Stream was:

- `outbound-onboarding`

The onboarding notification email should send to `hello@memba.io` without the user needing to inspect provider internals.

## What happened

The production form submission reached the application and was accepted, but the staff notification email failed. Production logs showed:

```text
Could not deliver onboarding request notification email:
{:onboarding_new_request_email_delivery_error,
 {422,
  %{"ErrorCode" => 1235,
    "Message" => "The stream provided: 'outbound-onboarding' does not exist on this server."}}}
```

The missing stream was only discovered after Matt noticed that no `*@memba.io` email had arrived and asked for production logs to be checked.

We created `outbound-onboarding` as a Transactional stream on both:

- Postmark production server `memba.io`
- Postmark dev server `memba local dev`

We then re-sent the failed production onboarding notification and Postmark reported it as sent to `hello@memba.io`.

## Impact

This was customer-facing during a production onboarding test: Memba accepted an onboarding request but silently failed the staff notification path from the user's point of view. The request still existed, but staff would not know about it by email without log inspection or manually checking the request inbox.

It also caused operator work: production log archaeology, provider configuration inspection, creating missing resources, and manually re-sending the failed notification.

## What allowed it to happen

The delivery workflow had no guardrail confirming that the named Postmark message stream existed on each target server before the feature was treated as production-ready.

The app did log a clear provider error, but the abnormality appeared only at runtime after a real form submission. The deployment/check workflow did not catch the missing external provider resource.

There also appears to be no documented checklist tying the app config value `outbound-onboarding` to required Postmark setup for both production and dev servers.

## Observations

- The application config named a concrete provider resource: `outbound-onboarding`.
- The provider rejected the send with Postmark error `1235` because the stream did not exist.
- The missing resource affected production and dev Postmark servers, so the setup gap was not environment-specific.
- The user-visible success page did not mean the notification email had succeeded.
- Recovery was possible because the request record existed and the notification could be re-sent after the stream was created.

## Why this matters

External-provider resources are part of the production system. If they are not created, verified, or documented alongside code/config changes, email-dependent features can pass local tests and deployment but fail at the first real production use.

This is especially risky for onboarding because the failure mode is quiet: the requester sees a successful submission, but staff may not receive the operational signal to act.

## Open questions

- Should onboarding request notification failures create a visible staff/admin alert or retryable delivery record?
- Where should provider-resource preflight live: deploy script, `dev check`, smoke test, runbook, or a dedicated operational check?
- Should dev startup sync/create required Postmark streams, or only verify and report missing streams?

## Possible prevention ideas

- Add a preflight check that verifies required Postmark streams exist for the selected server before production smoke/manual testing.
- Document required streams in the onboarding iteration release checklist or Postmark runbook.
- Add an operational check that compares configured message stream IDs with Postmark server state.
- Include onboarding notification delivery in production smoke testing with a controlled recipient/mailbox.
