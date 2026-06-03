# 16. Use Resend as a switchable email provider

Date: 2026-06-01

## Status

accepted

## Context

Memba needs real email delivery for member messages and magic-link authentication so we can test the end-to-end production lifecycle: provider handoff, inbox receipt, delivered/opened/bounced/spam/delayed events, and correlation back to Memba delivery records.

Postmark was the original provider choice and remains a good fit for transactional email, but account activation is blocking immediate testing. Waiting for Postmark would delay production-like validation of the messaging and auth slices.

Resend has been faster to set up, has a Swoosh adapter in the version already used by Memba, and can send real email through the same `Memba.Mailer` boundary. Resend also supports webhook events for the lifecycle we need to observe. The main difference is provider-specific payload shape: Memba's existing webhook integration was Postmark-shaped, so Resend needs its own webhook parser and correlation strategy.

We also want to avoid locking Memba to one email provider. Email deliverability, account review, pricing, API behaviour, and operational needs may change. The application should preserve the option to switch between Postmark and Resend through runtime configuration.

## Decision

Support Resend as a first-class, switchable email provider alongside Postmark.

Postmark is the intended primary production provider once the account is
approved and production setup is complete. Resend remains a first-class fallback,
not a deprecated or temporary code path.

For member-message email:

- `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` selects the existing Postmark provider.
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=resend` selects the Resend provider.
- Leaving the variable unset preserves the configured default, which remains fake/local in routine development and tests.

For magic-link authentication email:

- `MEMBA_AUTH_EMAIL_PROVIDER=postmark` selects Postmark.
- `MEMBA_AUTH_EMAIL_PROVIDER=resend` selects Resend.

Use Swoosh adapters for both providers rather than adding direct provider HTTP code. Resend uses `Swoosh.Adapters.Resend` with `Swoosh.ApiClient.Req`.

Add a dedicated Resend webhook endpoint at:

```text
POST /webhooks/resend
```

Keep the existing Postmark endpoint at:

```text
POST /webhooks/postmark
```

Use a distinct Postmark inbound-email endpoint for club-message email so
delivery-status webhooks and inbound email webhooks do not share payload parsing
or routing assumptions:

```text
POST /webhooks/postmark/inbound
```

Resend outbound member-message emails include Memba correlation data using Resend tags and `X-Memba-*` headers:

- `memba_message_id`
- `memba_delivery_id`
- `memba_club_id`

The Resend webhook handler maps delivered, opened, delayed, bounced, and complained/spam-complaint events onto the existing Messaging status-reporting API. This keeps the domain model and read projections provider-neutral.

## Consequences

We can start real email lifecycle testing immediately with Resend without waiting for Postmark activation.

Memba keeps provider choice at the runtime configuration boundary. Switching between Postmark and Resend does not require changing the domain model, command handlers, projections, member UI, or staff delivery views.

The application now has two provider-specific webhook parsers to maintain. This is acceptable because provider payloads differ and the domain-facing status-reporting API remains shared.

Operational documentation and deployment secrets must distinguish Postmark and Resend settings clearly. Fly.io deployments can select either provider using secrets.

Webhook authenticity remains a follow-up security concern. Before relying on provider webhooks for production customer data, each provider endpoint should verify the provider's webhook signature or equivalent authentication mechanism.

Postmark approval completed after this ADR was accepted. Iteration 020 makes
Postmark the intended primary production provider for member-message delivery,
rejection emails, magic-link authentication, and inbound club-message email.
Resend remains selectable for member-message delivery, auth email, and inbound
handling so production can roll back without changing the domain model, command
handlers, projections, member UI, or staff delivery views.

Keeping Resend as a fallback means tests and documentation must continue to cover
both provider paths. Removing Resend support requires a later ADR or an explicit
iteration plan that replaces the rollback strategy.
