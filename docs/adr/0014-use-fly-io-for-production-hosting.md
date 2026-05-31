# 14. Use Fly.io for production hosting

Date: 2026-05-31

## Status

accepted

## Context

Memba needs a production hosting environment for the Phoenix application, Postgres database, HTTPS custom domains, and Postmark webhooks.

The first production environment should be simple enough for a solo founder to operate, cheap at low traffic, and compatible with Phoenix releases. It also needs to support `memba.io` plus wildcard club subdomains such as `kmc.memba.io` for future white-label club websites.

## Decision

Use Fly.io as Memba's initial production hosting platform.

The production app is `memba`, deployed as a Dockerized Phoenix release. It uses:

- Fly Machines for the Phoenix web process.
- A Fly Postgres app, `memba-db`, for the primary application database and EventStore schema.
- Fly-managed certificates for `memba.io`, `www.memba.io`, and `*.memba.io`.
- DNSimple DNS records pointing the apex, `www`, and wildcard subdomains to Fly ingress IPs.
- Fly secrets for production configuration, including `DATABASE_URL`, `SECRET_KEY_BASE`, Postmark settings, and Phoenix host/server configuration.

Keep the initial app footprint small: one web machine and a small Postgres instance until traffic or availability requirements justify scaling.

## Consequences

Production deploys can use `flyctl deploy`, with the release command running migrations before rollout.

Fly's wildcard certificate and wildcard DNS support lets us route club subdomains to the same Phoenix application, leaving app-level routing to map hosts such as `kmc.memba.io` to club pages such as `/clubs/kmc` or an equivalent future route.

We accept some Fly-specific operational knowledge in exchange for fast setup, low ceremony, and straightforward Phoenix release deployment. If Memba later needs managed database operations, stricter compliance, or multi-region data guarantees, we may revisit the database or hosting choice.

Fly's unmanaged Postgres requires operational care. Backups, restore testing, monitoring, and upgrade policy must be made explicit before relying on the service for real customer data.
