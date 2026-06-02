# 19. Use lvh.me for local club subdomains

Date: 2026-06-01

## Status

accepted

## Context

Memba uses club slugs as subdomains for club-site URLs in production, for example:

```text
https://kmc.clubs.memba.io/
```

Member-facing browser flows should exercise the same host-based routing in local development and acceptance tests. Replacing production subdomains with `?club_id=<uuid>` query strings in local/test would make the most important routing behaviour environment-specific and could hide production bugs.

`/etc/hosts` is not a good fit for this because it does not support wildcard records. Explicit entries such as `127.0.0.1 kmc.local` work only for known slugs and become brittle with generated test data.

Running a local DNS service through devenv/process-compose or another supervisor is possible, but every browser, test runner, container, and OS resolver still has to use that DNS server. That adds operational complexity to a workflow that only needs wildcard names resolving to loopback.

Public wildcard DNS services such as `lvh.me`, `nip.io`, and `sslip.io` can solve this without local resolver configuration. `lvh.me` and `*.lvh.me` resolve to `127.0.0.1`, which matches Memba's local Phoenix server use case.

## Decision

Use a configurable club-site base domain for generated club-site URLs.

- Production uses `clubs.memba.io`.
- Local development and browser acceptance tests default to `lvh.me`.
- Local club URLs therefore look like `http://kmc.lvh.me:4000/`.

New member navigation should use slug subdomains rather than `?club_id=<uuid>` links.

Keep legacy `?club_id=<uuid>` support only as a temporary backwards-compatible fallback while the member surface is migrated. Do not treat the fallback as the local-development strategy.

Use `nip.io` or `sslip.io` only when a workflow needs to encode a non-loopback IP address in the hostname, for example testing from another device on a LAN.

Do not add a project-managed DNS server unless `lvh.me` no longer meets the workflow needs and the resolver configuration burden is justified by a concrete use case.

## Consequences

Acceptance tests and local manual demos can exercise real host-based club routing with URLs like `kmc.lvh.me:4000`, reducing the risk that query-string-only local behaviour diverges from production.

Developers do not need wildcard `/etc/hosts` entries or a local DNS daemon for the common case.

Generated URLs need an environment-specific club-site base-domain configuration. Tests should verify both host extraction and URL generation.

The project depends on public DNS for `lvh.me` during local browser tests. If that becomes unreliable, the decision can be revisited or a narrower local DNS solution can be introduced.
