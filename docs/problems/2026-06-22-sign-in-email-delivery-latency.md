# Problems

## Sign-in email delivery can be slow enough that links expire before use

Observed: 2026-06-22

Status: Unresolved. Auth-stream Postmark webhooks were configured during diagnosis on 2026-06-22, so future sign-in email delivery events should be recorded in `auth_email_requests`. The underlying cause of delayed mailbox-provider acceptance is still unknown.

Memba sign-in depends on a one-use email link reaching the recipient quickly. During production sign-in testing, a sign-in email was accepted by Postmark immediately but did not arrive in the Fastmail-hosted `matt@memba.io` mailbox until nearly the end of the 15-minute token lifetime. When opened, the sign-in link was already invalid or close enough to expiry to make sign-in unreliable.

Observed evidence from production diagnosis:

- Memba created and sent auth request `aer_24d35c26-39a3-4779-a42e-7cf5d2d8183e` at about `2026-06-22 07:16:22Z`.
- Postmark message `3f0466ac-33c7-459e-b490-d4be82f565c1` was received by Postmark at about `07:16:23Z`.
- Postmark recorded SMTP delivery to Fastmail at about `07:30:01Z`, with Fastmail response `250 2.0.0 Ok: queued as DEACB1EA008B`.
- Fastmail filed the message in `Inbox/Screener` at about `07:30:03Z`.
- A later sign-in email, Postmark message `1a4a9c88-628d-4bb1-8517-b8c417d82bee`, took about 302 seconds from Postmark receipt to SMTP delivery.
- After auth-stream webhooks were configured, a subsequent sign-in request `aer_3b306c3f-276b-4fb7-891c-dd25ea26b014` recorded `provider_accepted` in Memba within about 5 seconds, showing the new observability path works for future messages.

Expected:

- Sign-in emails reach normal mailboxes within a few seconds under ordinary conditions.
- If a provider delays, bounces, or rejects a sign-in email, Memba records and surfaces that status quickly enough for the user or staff to act.
- Sign-in should not rely on users waiting for a stale email that may arrive too late to use.
- Staff should have enough message IDs, provider event data, and timestamps to ask Postmark/Fastmail support for a precise explanation.

Impact:

- Affected users cannot sign in even though Memba created a valid token and handed the email to Postmark successfully.
- The failure is confusing because the email may eventually arrive but the link no longer works.
- Before auth-stream webhooks were configured, Memba could only show that the email had been sent, not whether the recipient mailbox provider had accepted it.

Open questions:

- Did Fastmail temporarily defer or greylist Postmark delivery for these messages, or was the delay caused elsewhere in the Postmark-to-Fastmail path?
- Does Fly.io machine auto-stop/start on the current plan contribute to stale connections, delayed webhook handling, delayed sign-in request processing, or other timing behaviour? Current evidence shows the observed delay was between Postmark receipt and Fastmail SMTP acceptance, but this hypothesis should still be tested rather than dismissed.
- Are repeated test/smoke sign-in emails to `memba.io` addresses affecting recipient-domain or sender-pattern reputation? This is only a hypothesis until supported by provider data.
- Should auth email use a separate provider, sender domain, or monitored delivery path from member-message email?
- What operational alert should fire when auth emails are not provider-accepted within a few seconds?

Possible follow-up:

- Use the newly configured Postmark `outbound-authentication` webhook data to collect more delivery timings and failure reasons.
- Ask Postmark and/or Fastmail support about specific delayed auth message IDs, including `3f0466ac-33c7-459e-b490-d4be82f565c1` and `1a4a9c88-628d-4bb1-8517-b8c417d82bee`.
- Add a staff-facing auth-email diagnostics view or operational report backed by `auth_email_requests`.
- Add a production health check that exercises sign-in email delivery to a controlled mailbox and fails if provider acceptance or mailbox arrival is slow.
