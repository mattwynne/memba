---
name: dnsimple
description: Read, audit, and safely manipulate DNSimple DNS configuration through the DNSimple API. Use when inspecting domains, zones, DNS records, or making explicit DNS changes with a DNSimple API token from the environment.
---

# DNSimple

Use this skill for reading, auditing, and safely changing DNS configuration through the DNSimple API.

The DNSimple API token is expected to be available in the shell environment. Do not print the token, commit it, or paste it into files. Prefer read-only API calls unless Matt explicitly asks for a DNS change.

## Safety Rules

- Treat DNS changes as production-impacting.
- For read-only requests, use `GET` freely.
- For mutating requests (`POST`, `PATCH`, `DELETE`), proceed only when Matt explicitly asks to create, update, or delete DNSimple configuration.
- Before any mutation:
  1. Read the current relevant record/configuration.
  2. State the exact requested change in terms of domain, record name, type, content/value, TTL, priority/regions if relevant, and API endpoint.
  3. If the request is ambiguous or broad, ask a clarifying question.
- After a mutation, read the affected resource back and report the resulting state.
- Never expose `Authorization` headers or token values in logs or responses.

## Environment Setup

Look for the token without echoing its value:

```bash
if [ -n "${DNSIMPLE_API_TOKEN:-}" ]; then echo DNSIMPLE_API_TOKEN; \
elif [ -n "${DNSIMPLE_TOKEN:-}" ]; then echo DNSIMPLE_TOKEN; \
elif [ -n "${DNSIMPLE_ACCESS_TOKEN:-}" ]; then echo DNSIMPLE_ACCESS_TOKEN; \
else echo "No DNSimple token env var found"; fi
```

Use a local shell variable so commands work with whichever variable exists:

```bash
DNSIMPLE_TOKEN_VALUE="${DNSIMPLE_API_TOKEN:-${DNSIMPLE_TOKEN:-${DNSIMPLE_ACCESS_TOKEN:-}}}"
test -n "$DNSIMPLE_TOKEN_VALUE" || { echo "Missing DNSimple API token" >&2; exit 1; }
```

Base URL:

```bash
DNSIMPLE_BASE_URL="https://api.dnsimple.com"
```

Common curl flags:

```bash
-H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
-H "Accept: application/json" \
-H "Content-Type: application/json"
```

Use `jq` for readable output when available. Do not use `set -x` around authenticated commands.

## Discover Account and Domains

Identify the account ID:

```bash
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/whoami" | jq .
```

The account ID is usually at `.data.account.id`.

List domains:

```bash
ACCOUNT_ID="<account-id>"
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/domains" | jq .
```

Get one domain:

```bash
DOMAIN="example.com"
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/domains/$DOMAIN" | jq .
```

## DNS Records

List zone records:

```bash
DOMAIN="example.com"
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records" | jq .
```

Filter by name or type using query parameters:

```bash
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records?name=www&type=CNAME" | jq .
```

Read one record:

```bash
RECORD_ID="<record-id>"
curl -sS \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records/$RECORD_ID" | jq .
```

Create a record only when explicitly requested:

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records" \
  -d '{
    "name": "www",
    "type": "CNAME",
    "content": "example.com",
    "ttl": 3600
  }' | jq .
```

Update a record only when explicitly requested:

```bash
curl -sS -X PATCH \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records/$RECORD_ID" \
  -d '{
    "content": "new-target.example.com",
    "ttl": 3600
  }' | jq .
```

Delete a record only when explicitly requested:

```bash
curl -sS -X DELETE \
  -H "Authorization: Bearer $DNSIMPLE_TOKEN_VALUE" \
  -H "Accept: application/json" \
  "$DNSIMPLE_BASE_URL/v2/$ACCOUNT_ID/zones/$DOMAIN/records/$RECORD_ID"
```

## Record Payload Notes

Common fields:

- `name`: record host/name. Use `""` for apex/root records when DNSimple expects an empty host.
- `type`: `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`, `SRV`, `CAA`, etc.
- `content`: target/value.
- `ttl`: seconds.
- `priority`: required for `MX` and some other record types.
- Additional fields may apply to ALIAS/URL/service records; read the existing record and DNSimple docs/API response shape before editing.

## Useful Checks

Compare DNSimple configuration with public DNS:

```bash
dig +short example.com A
dig +short www.example.com CNAME
dig +short example.com MX
dig +short example.com TXT
```

Remember public DNS may lag because of TTLs and resolver caches. DNSimple API reads are the source of truth for DNSimple-managed configuration; `dig` shows what resolvers currently see.

## Reporting Format

When reporting DNSimple work, include:

- Account/domain inspected.
- Records or configuration read.
- For changes: before state, requested change, after state, and any propagation caveats.
- Any ambiguity, risk, or follow-up needed.
