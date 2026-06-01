1. **Selected todo line**
   - `001 Confirm production DNS prerequisite outside Fabro: *.clubs.memba.io points at the production Memba app before delivery starts.`

2. **Changes made**
   - Updated `docs/iterations/015-club-slugs/dns-prerequisite.md` with durable confirmation evidence.
   - Recorded that `kmc.clubs.memba.io` and `unknown.clubs.memba.io` resolve to the same Fly ingress addresses as:
     - `memba.io`
     - `memba.fly.dev`
   - No application code or acceptance feature files changed.

3. **Validation run**
   - Focused DNS validation:
     ```sh
     python3 - <<'PY'
     import socket, sys
     hosts = ['memba.io', 'memba.fly.dev', 'kmc.clubs.memba.io', 'unknown.clubs.memba.io']
     ...
     PY
     ```
     Result: passed. All hosts resolved to:
     - `66.241.124.49`
     - `2a09:8280:1::11d:7250:0`

   - Full project validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check
     ```
     Result: passed — `257 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly this line:
     ```md
     - [x] 001 Confirm production DNS prerequisite outside Fabro: `*.clubs.memba.io` points at the production Memba app before delivery starts.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspected `docs/adr/0014-use-fly-io-for-production-hosting.md`.
   - Confirmation aligns with ADR 0014: production app is Fly.io app `memba`, and the club wildcard DNS resolves to the same Fly ingress addresses as the production Memba app.