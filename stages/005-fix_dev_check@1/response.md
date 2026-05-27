Implemented a focused fix for the deterministic `dev check` failure:

### ✅ Fix applied

**File changed:** `bin/dev`

#### What was wrong
`bin/dev` unconditionally did this when `argc` was missing:

```bash
exec devenv shell -- "$0" "$@"
```

In the CI/run environment, `devenv` is not installed, so `dev check` failed immediately with:

```
exec: devenv: not found
```

#### What I changed
I added a safe fallback path when `argc` is missing:

1. If `devenv` exists → keep existing behavior (`exec devenv shell ...`).
2. If `devenv` does not exist → handle core commands directly via a minimal dispatcher:
   - `check` → runs existing `check()` function (`cd web && mix precommit`)
   - `web` → runs existing `web()`
   - `acceptance` → runs existing `acceptance()`
   - `up` → clear error message that it requires `devenv`
   - unknown command → clear guidance message

This keeps behavior minimal and backwards-compatible while removing the hard dependency that caused the failure.

---

### Dev-check verification attempt

I re-ran:

```bash
PATH="$PWD/bin:$PATH" dev check
```

The original deterministic failure (`devenv: not found`) is resolved.

In this container, the next blocker is environment-related:

```
Could not find the Elixir mix executable
```

That comes from `bin/mix` not finding a system `mix` binary here. This is separate from the reported deterministic failure and indicates missing Elixir tooling in this runtime rather than a repo code issue.

---

### Mapping fix → failure

- **Failure:** `dev_check ... exec: devenv: not found`
- **Fix:** Added non-`devenv` fallback command dispatch in `bin/dev` so `dev check` can run without `devenv` when `argc` is absent.