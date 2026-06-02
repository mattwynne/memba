# lvh.me

`lvh.me` is a public wildcard DNS name for loopback local development.

## What it does

`lvh.me` and its subdomains resolve to `127.0.0.1`:

```text
lvh.me            -> 127.0.0.1
kmc.lvh.me        -> 127.0.0.1
anything.lvh.me   -> 127.0.0.1
```

That lets a local web app exercise host-based or subdomain-based routing without editing `/etc/hosts` or running a local DNS server.

For Memba, local club-site URLs can therefore mirror production subdomain routing:

```text
http://kmc.lvh.me:4000/
```

The browser resolves `kmc.lvh.me` to the local machine, then connects to the Phoenix server on port `4000`. Phoenix still receives the requested host as `kmc.lvh.me`, so the app can select the club from the subdomain.

## Why Memba uses it

Production club-site URLs use the configured production base domain, currently:

```text
https://kmc.clubs.memba.io/
```

Local development and browser acceptance tests default to:

```text
http://kmc.lvh.me:<port>/
```

This keeps the important behaviour — selecting a club from the host — the same in local/test and production. It avoids a weaker local-only strategy such as `?club_id=<uuid>` query strings.

## Limits and cautions

- `lvh.me` points to `127.0.0.1`, so it is for services running on the same machine as the browser or test runner.
- Use the URL port to target the local service, for example `:4000` for Phoenix or an acceptance-test port.
- It depends on public DNS. If DNS resolution is unavailable or blocked, local browser tests that use `lvh.me` may fail.
- For testing from another device on a LAN, use a service such as `nip.io` or `sslip.io` that can encode a non-loopback IP address in the hostname.
- Do not expect `https://lvh.me/` to provide useful documentation: the name resolves to your own machine, so a browser or `curl` will try to connect locally.

## Memba references

- `docs/adr/0019-use-lvh-me-for-local-club-subdomains.md`
- `docs/iterations/018-member-club-subdomains/plan.md`
- `web/config/dev.exs`
- `web/config/test.exs`
- `web/lib/memba_web/club_site.ex`
