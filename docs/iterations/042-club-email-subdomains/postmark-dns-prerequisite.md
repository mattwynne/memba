# Postmark and DNS prerequisite for iteration 042

Before running implementation for iteration 042, Matt should update production inbound mail routing so Postmark receives mail for club email subdomains.

## Desired production shape

Members send club-wide messages to:

```text
everyone@<club-slug>.clubs.memba.io
```

Smoke-test club address:

```text
everyone@test.clubs.memba.io
```

## Postmark

On the production Postmark server currently used for Memba inbound mail:

- Inbound domain: `*.clubs.memba.io`
- Inbound webhook URL: keep `https://memba.io/webhooks/postmark/inbound`

Postmark documentation says wildcard inbound domains are supported and route messages addressed to any subdomain of the configured domain to the inbound endpoint.

## DNS

Add or update the wildcard MX record for club email subdomains:

```text
*.clubs.memba.io MX 10 inbound.postmarkapp.com
```

The existing flat-domain record may still exist during setup:

```text
clubs.memba.io MX 10 inbound.postmarkapp.com
```

Iteration 042 will hard-cut the app behaviour to the new address shape; keeping the old MX temporarily should not make the old address accepted by the app.

## Pre-implementation check

After changing Postmark/DNS, wait for DNS propagation and verify:

```bash
dig +short MX test.clubs.memba.io
```

Expected result includes:

```text
10 inbound.postmarkapp.com.
```

Then run iteration 042 implementation. The implementation should update and run the production smoke test against `everyone@test.clubs.memba.io`.
