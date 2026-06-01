# DNS prerequisite for iteration 015

Before running Fabro delivery for `docs/iterations/015-club-slugs/plan.md`, configure production DNS so public club subdomains can reach the Memba production app.

## Required record

- Host pattern: `*.clubs.memba.io`
- Target: the production Memba application endpoint, using the record type required by the hosting provider.

## Notes

- This DNS change is intentionally outside Fabro delivery. Fabro should implement application host resolution and validation, not operate production DNS.
- The application behaviour planned by iteration 015 is public club-page routing only: `kmc.clubs.memba.io` resolves to the club whose slug is `kmc`.
- Member authenticated routes, inbound email, custom club domains, and slug aliases are out of scope.

## Confirmation before Fabro delivery

Confirmed on 2026-06-01 from the Fabro sandbox that representative wildcard club hosts resolve to the same Fly ingress addresses as the production Memba app:

| Host | Resolved addresses |
| --- | --- |
| `memba.io` | `66.241.124.49`, `2a09:8280:1::11d:7250:0` |
| `memba.fly.dev` | `66.241.124.49`, `2a09:8280:1::11d:7250:0` |
| `kmc.clubs.memba.io` | `66.241.124.49`, `2a09:8280:1::11d:7250:0` |
| `unknown.clubs.memba.io` | `66.241.124.49`, `2a09:8280:1::11d:7250:0` |

## Manual validation after delivery/deploy

1. Confirm `kmc.clubs.memba.io` resolves to the production Memba app.
2. Confirm opening `https://kmc.clubs.memba.io` shows Kootenay Mountaineering Club's public club page after the app is deployed.
3. Confirm opening an unknown slug host such as `https://unknown.clubs.memba.io` returns a 404 Not Found response.
