---
name: postmark
description: Read, audit, and safely manipulate Postmark configuration and message data through the Postmark API. Use when inspecting servers, streams, senders, domains, templates, messages, webhooks, suppressions, or making explicit Postmark changes with API tokens from the environment.
---

# Postmark

Use this skill for reading, auditing, and safely changing Postmark configuration through the Postmark API.

Postmark uses different tokens for different API areas. Tokens are expected to be available in the shell environment. Do not print tokens, commit them, or paste them into files. Prefer read-only API calls unless Matt explicitly asks for a Postmark change.

## Safety Rules

- Treat email configuration changes as production-impacting.
- For read-only requests, use `GET` freely.
- For mutating requests (`POST`, `PUT`, `PATCH`, `DELETE`), proceed only when Matt explicitly asks to create, update, delete, resend, or suppress something in Postmark.
- Before any mutation:
  1. Read the current relevant configuration or message state.
  2. State the exact requested change in terms of server, message stream, sender/domain/template/webhook/suppression, payload, and API endpoint.
  3. If the request is ambiguous or broad, ask a clarifying question.
- After a mutation, read the affected resource back when the API supports it and report the resulting state.
- Never expose `X-Postmark-Server-Token`, `X-Postmark-Account-Token`, or token values in logs or responses.
- Do not send or resend real email unless Matt explicitly asks.

## Tokens and Base URL

Postmark API base URL:

```bash
POSTMARK_BASE_URL="https://api.postmarkapp.com"
```

Server API token candidates, used for server-scoped operations such as messages, templates, webhooks, suppressions, and outbound/inbound details:

```bash
if [ -n "${POSTMARK_SERVER_TOKEN:-}" ]; then echo POSTMARK_SERVER_TOKEN; \
elif [ -n "${POSTMARK_API_TOKEN:-}" ]; then echo POSTMARK_API_TOKEN; \
elif [ -n "${POSTMARK_TOKEN:-}" ]; then echo POSTMARK_TOKEN; \
else echo "No Postmark server token env var found"; fi
```

Account API token candidates, used for account-scoped operations such as listing servers, sender signatures, and domains:

```bash
if [ -n "${POSTMARK_ACCOUNT_TOKEN:-}" ]; then echo POSTMARK_ACCOUNT_TOKEN; \
else echo "No Postmark account token env var found"; fi
```

Set local shell variables without echoing values:

```bash
POSTMARK_SERVER_TOKEN_VALUE="${POSTMARK_SERVER_TOKEN:-${POSTMARK_API_TOKEN:-${POSTMARK_TOKEN:-}}}"
POSTMARK_ACCOUNT_TOKEN_VALUE="${POSTMARK_ACCOUNT_TOKEN:-}"
```

Use `jq` for readable output when available. Do not use `set -x` around authenticated commands.

## Account-Scoped Reads

These require the account token header.

List servers:

```bash
test -n "$POSTMARK_ACCOUNT_TOKEN_VALUE" || { echo "Missing Postmark account token" >&2; exit 1; }
curl -sS \
  -H "X-Postmark-Account-Token: $POSTMARK_ACCOUNT_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/servers?count=100&offset=0" | jq .
```

List sender signatures:

```bash
curl -sS \
  -H "X-Postmark-Account-Token: $POSTMARK_ACCOUNT_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/senders?count=100&offset=0" | jq .
```

List domains:

```bash
curl -sS \
  -H "X-Postmark-Account-Token: $POSTMARK_ACCOUNT_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/domains?count=100&offset=0" | jq .
```

Read one domain:

```bash
DOMAIN_ID="<domain-id>"
curl -sS \
  -H "X-Postmark-Account-Token: $POSTMARK_ACCOUNT_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/domains/$DOMAIN_ID" | jq .
```

## Server-Scoped Reads

These require the server token header.

Get server details for the token:

```bash
test -n "$POSTMARK_SERVER_TOKEN_VALUE" || { echo "Missing Postmark server token" >&2; exit 1; }
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/server" | jq .
```

List message streams:

```bash
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/message-streams" | jq .
```

List templates:

```bash
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/templates?Count=100&Offset=0" | jq .
```

Read one template:

```bash
TEMPLATE_ID_OR_ALIAS="<template-id-or-alias>"
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/templates/$TEMPLATE_ID_OR_ALIAS" | jq .
```

List webhooks:

```bash
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/webhooks" | jq .
```

## Messages

Search outbound messages:

```bash
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/messages/outbound?count=50&offset=0" | jq .
```

Search inbound messages:

```bash
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/messages/inbound?count=50&offset=0" | jq .
```

Read outbound message details:

```bash
MESSAGE_ID="<message-id>"
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/messages/outbound/$MESSAGE_ID/details" | jq .
```

Read inbound message details:

```bash
MESSAGE_ID="<message-id>"
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/messages/inbound/$MESSAGE_ID/details" | jq .
```

Open/click/bounce endpoints expose potentially sensitive recipient and content metadata. Fetch only the fields needed for the task and avoid pasting unnecessary personal data into responses.

## Suppressions

List suppressions for a message stream:

```bash
MESSAGE_STREAM="outbound"
curl -sS \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/message-streams/$MESSAGE_STREAM/suppressions/dump?count=100&offset=0" | jq .
```

Create or delete suppressions only when explicitly requested, because this changes mail delivery behaviour.

## Mutating Examples

Create a webhook only when explicitly requested:

```bash
curl -sS -X POST \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$POSTMARK_BASE_URL/webhooks" \
  -d '{
    "Url": "https://example.com/postmark/webhook",
    "MessageStream": "outbound",
    "Triggers": {
      "Delivery": {"Enabled": true},
      "Bounce": {"Enabled": true},
      "Open": {"Enabled": false},
      "Click": {"Enabled": false}
    }
  }' | jq .
```

Update a webhook only when explicitly requested:

```bash
WEBHOOK_ID="<webhook-id>"
curl -sS -X PUT \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$POSTMARK_BASE_URL/webhooks/$WEBHOOK_ID" \
  -d '{
    "Url": "https://example.com/postmark/webhook",
    "MessageStream": "outbound",
    "Triggers": {
      "Delivery": {"Enabled": true},
      "Bounce": {"Enabled": true},
      "Open": {"Enabled": false},
      "Click": {"Enabled": false}
    }
  }' | jq .
```

Delete a webhook only when explicitly requested:

```bash
WEBHOOK_ID="<webhook-id>"
curl -sS -X DELETE \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$POSTMARK_BASE_URL/webhooks/$WEBHOOK_ID"
```

Send a test email only when explicitly requested:

```bash
curl -sS -X POST \
  -H "X-Postmark-Server-Token: $POSTMARK_SERVER_TOKEN_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$POSTMARK_BASE_URL/email" \
  -d '{
    "From": "sender@example.com",
    "To": "recipient@example.com",
    "Subject": "Test",
    "TextBody": "Test message",
    "MessageStream": "outbound"
  }' | jq .
```

## Reporting Format

When reporting Postmark work, include:

- Token scope used: server token or account token. Do not include token values.
- Server, stream, domain, sender, template, webhook, suppression, or message inspected.
- For changes: before state, requested change, endpoint used, after state, and delivery/recipient impact.
- Any ambiguity, risk, or follow-up needed.
