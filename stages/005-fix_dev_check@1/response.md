Implemented the smallest scoped fix for the deterministic `dev_check` failure.

## 1. Dev check failure from preceding stage

| Failure | Cause |
|---|---|
| `MembaWeb.Plugs.CanonicalHostRedirectTest` expected `/admin/clubs` on canonical host to return `200`, but received `302` redirect to `/auth` | Iteration 010 correctly made `/admin/*` staff-protected. The canonical-host test was still hitting a protected admin route without an authenticated staff session. |

## 2. Concrete change made

Updated the canonical-host redirect test to authenticate as a Memba staff identity before requesting `/admin/clubs` on `memba.io`.

This preserves the original intent of the test:

- Fly hostname redirects to canonical domain.
- Canonical hostname itself does not trigger the canonical-host redirect.
- `/admin/clubs` can still return the expected page when accessed by authorized staff.

## 3. Files changed

### Failure: canonical-host test redirected to `/auth`

- `web/test/memba_web/plugs/canonical_host_redirect_test.exs`
  - Added `alias MembaWeb.UserAuth`.
  - Added `init_test_session(%{UserAuth.identity_session_key() => "pat@memba.io"})` before requesting `/admin/clubs`.

## 4. Tests run and results

- `PATH="$PWD/bin:$PATH" mix test test/memba_web/plugs/canonical_host_redirect_test.exs`
  - Failed due sandbox/runtime PostgreSQL socket incoherence:
    - Postgres started on `/tmp/devenv-1d7df38/postgres`
    - Readiness check expected `/tmp/devenv/postgres`
  - No product-code failure observed from this command.

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed.
  - `194 tests, 0 failures`.

- `PATH="$PWD/bin:$PATH" dev ci`
  - Passed.
  - `194 tests, 0 failures`.

## 5. Remaining failures or questions

None.

Working tree changes are limited to:

```text
M web/test/memba_web/plugs/canonical_host_redirect_test.exs
?? .fabro/tmp/
```

`.fabro/tmp/` was already present as review scratch state.