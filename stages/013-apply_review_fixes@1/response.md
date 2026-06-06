Implemented the bounded review repair.

## 1. Review issue from gate

| Issue ID | Review issue | Status |
|---|---|---|
| `canonical-host-test-copy-coupling` | Decouple canonical host redirect test from homepage marketing copy | Fixed |

## 2. Changes made

### `canonical-host-test-copy-coupling`

Changed the canonical-host no-redirect test so it no longer asserts the homepage marketing headline:

```elixir
assert conn.status == 200
assert get_resp_header(conn, "location") == []
```

This keeps the test focused on canonical-host redirect behaviour:
- canonical hostname serves a normal 200 response;
- no `location` header is set;
- homepage copy can change without breaking an unrelated plug test.

No product behaviour, routing, templates, acceptance features, or copy were changed.

## 3. Files changed

### Issue: `canonical-host-test-copy-coupling`

- `web/test/memba_web/plugs/canonical_host_redirect_test.exs`

## 4. Tests run

- `PATH="$PWD/bin:$PATH" dev ci`
  - Result: passed
  - ExUnit: `566 tests, 0 failures`
  - Acceptance: `44 scenarios (44 passed)`, `291 steps (291 passed)`

Also attempted a direct targeted Mix run:

- `cd web && mix test test/memba_web/plugs/canonical_host_redirect_test.exs`
  - Result: failed due local runtime/service setup outside the dev helper:
    - Postgres socket missing at `/tmp/devenv/postgres/.s.PGSQL.15432`
  - I did not patch scripts/product code for this runtime boundary. The required project quality gate succeeded.

## 5. Remaining gaps or human questions

None.

Working tree note: only the intended tracked test file is modified. `.fabro/tmp/` remains untracked runtime state.