# lvh.me source notes

- Tool/service: `lvh.me`
- Type: public wildcard DNS name for local development
- Upstream website: `http://lvh.me` / `https://lvh.me`
- Fetch date: 2026-06-02

## Notes

No upstream documentation was imported into this directory.

The domain itself resolves to loopback, so fetching `http://lvh.me` or `https://lvh.me` from a development machine attempts to connect to a local service rather than an external documentation site.

The behaviour recorded here was verified with local DNS resolution:

```text
lvh.me              -> 127.0.0.1
foo.lvh.me          -> 127.0.0.1
bar.baz.lvh.me      -> 127.0.0.1
```

Project-specific rationale is recorded in `docs/adr/0019-use-lvh-me-for-local-club-subdomains.md`.
