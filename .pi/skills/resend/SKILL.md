---
name: resend
description: Read, audit, and safely manipulate Resend email configuration and message data through the Resend API. Use when inspecting domains, API keys, audiences, contacts, broadcasts, emails, webhooks, or making explicit Resend changes with an API key from the environment.
---

# Resend

Use this skill for reading, auditing, and safely changing Resend configuration through the Resend API.

The Resend API key is expected to be available in the shell environment. Do not print the key, commit it, or paste it into files. Prefer read-only API calls unless Matt explicitly asks for a Resend change.

## Safety Rules

- Treat email configuration changes as production-impacting.
- For read-only requests, use `GET` freely.
- For mutating requests (`POST`, `PATCH`, `PUT`, `DELETE`), proceed only when Matt explicitly asks to create, update, delete, send, or verify something in Resend.
- Before any mutation:
  1. Read the current relevant configuration or message state.
  2. State the exact requested change in terms of domain, email, audience, contact, broadcast, webhook, payload, and API endpoint.
  3. If the request is ambiguous or broad, ask a clarifying question.
- After a mutation, read the affected resource back when the API supports it and report the resulting state.
- Never expose `Authorization` headers or API key values in logs or responses.
- Do not send or resend real email unless Matt explicitly asks.

## Environment Setup

Look for the API key without echoing its value:

```bash
if [ -n "${RESEND_API_KEY:-}" ]; then echo RESEND_API_KEY; \
elif [ -n "${RESEND_TOKEN:-}" ]; then echo RESEND_TOKEN; \
elif [ -n "${RESEND_KEY:-}" ]; then echo RESEND_KEY; \
else echo "No Resend API key env var found"; fi
```

Use a local shell variable so commands work with whichever variable exists:

```bash
RESEND_API_KEY_VALUE="${RESEND_API_KEY:-${RESEND_TOKEN:-${RESEND_KEY:-}}}"
test -n "$RESEND_API_KEY_VALUE" || { echo "Missing Resend API key" >&2; exit 1; }
```

Base URL:

```bash
RESEND_BASE_URL="https://api.resend.com"
```

Common curl flags:

```bash
-H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
-H "Accept: application/json" \
-H "Content-Type: application/json"
```

Use `jq` for readable output when available. Do not use `set -x` around authenticated commands.

## Domains

List domains:

```bash
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/domains" | jq .
```

Read one domain:

```bash
DOMAIN_ID="<domain-id>"
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/domains/$DOMAIN_ID" | jq .
```

Create a domain only when explicitly requested:

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$RESEND_BASE_URL/domains" \
  -d '{"name":"example.com"}' | jq .
```

Verify a domain only when explicitly requested:

```bash
DOMAIN_ID="<domain-id>"
curl -sS -X POST \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/domains/$DOMAIN_ID/verify" | jq .
```

Delete a domain only when explicitly requested:

```bash
DOMAIN_ID="<domain-id>"
curl -sS -X DELETE \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/domains/$DOMAIN_ID"
```

Domain responses include DNS records Resend expects. When DNS is managed in DNSimple, use the DNSimple skill to read or update those records safely.

## Emails

Send email only when explicitly requested:

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$RESEND_BASE_URL/emails" \
  -d '{
    "from": "sender@example.com",
    "to": ["recipient@example.com"],
    "subject": "Test",
    "text": "Test message"
  }' | jq .
```

Read an email by ID:

```bash
EMAIL_ID="<email-id>"
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/emails/$EMAIL_ID" | jq .
```

Cancel a scheduled email only when explicitly requested:

```bash
EMAIL_ID="<email-id>"
curl -sS -X POST \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/emails/$EMAIL_ID/cancel" | jq .
```

## API Keys

List API keys:

```bash
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/api-keys" | jq .
```

Create or delete API keys only when explicitly requested. Treat key creation and deletion as security-sensitive changes. If a create response includes a secret key value, do not repeat it in chat unless Matt explicitly asks and the channel is appropriate.

## Audiences and Contacts

List audiences:

```bash
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/audiences" | jq .
```

Read one audience:

```bash
AUDIENCE_ID="<audience-id>"
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/audiences/$AUDIENCE_ID" | jq .
```

List contacts in an audience:

```bash
AUDIENCE_ID="<audience-id>"
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/audiences/$AUDIENCE_ID/contacts" | jq .
```

Create, update, or delete contacts only when explicitly requested, because this changes recipient data and mailing behaviour.

## Broadcasts

List broadcasts:

```bash
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/broadcasts" | jq .
```

Read one broadcast:

```bash
BROADCAST_ID="<broadcast-id>"
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/broadcasts/$BROADCAST_ID" | jq .
```

Create, update, schedule, send, or delete broadcasts only when explicitly requested. Confirm the audience and content before triggering delivery.

## Webhooks

List webhooks:

```bash
curl -sS \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  "$RESEND_BASE_URL/webhooks" | jq .
```

Create a webhook only when explicitly requested:

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $RESEND_API_KEY_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$RESEND_BASE_URL/webhooks" \
  -d '{
    "endpoint": "https://example.com/resend/webhook",
    "events": ["email.sent", "email.delivered", "email.bounced", "email.complained"]
  }' | jq .
```

Update or delete webhooks only when explicitly requested. Read existing webhook configuration first so unchanged event subscriptions are preserved.

## Useful Checks

Compare Resend domain requirements with public DNS:

```bash
dig +short example.com MX
dig +short example.com TXT
dig +short resend._domainkey.example.com TXT
```

Public DNS may lag because of TTLs and resolver caches. Resend API reads are the source of truth for Resend configuration; `dig` shows what resolvers currently see.

## Reporting Format

When reporting Resend work, include:

- API area inspected: domains, emails, API keys, audiences, contacts, broadcasts, or webhooks.
- Resource IDs/names inspected, without exposing secrets or unnecessary personal data.
- For changes: before state, requested change, endpoint used, after state, and delivery/recipient/security impact.
- Any ambiguity, risk, propagation caveat, or follow-up needed.
