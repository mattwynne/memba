Implemented a focused fix for the failing `dev_check` signature (`devenv: not found`) by updating `bin/dev` to support environments where `devenv`/`argc` may be absent.

### ✅ Fixes made

#### 1) `bin/dev` no longer unconditionally execs `devenv`
**Failure addressed:**  
`/repos/mattwynne/memba/bin/dev: line 7: exec: devenv: not found`

**Change:**  
- Added `have_devenv` detection.
- Only `exec devenv shell -- "$0" "$@"` when:
  - `argc` is missing **and**
  - `devenv` is actually installed.

#### 2) `up` / `down` handle missing `devenv` safely
**Failure class addressed:** robustness around deterministic missing tool
- `up` now starts services only when `devenv` exists; otherwise prints:
  - `devenv not found; skipping service startup`
- `down` no-ops if `devenv` is unavailable.

#### 3) Added manual command dispatch when `argc` is missing
- Preserves existing `argc` behavior when present.
- Provides a shell fallback for:
  - `up`, `down`, `ci`, `web`, `check`, `acceptance`, `help`.

#### 4) Restored executable bit on `bin/dev`
- `chmod +x bin/dev` (it had become non-executable during edit).

---

### Validation run

Ran the exact check command:

```bash
PATH="$PWD/bin:$PATH" dev ci
```

Result in this container:
- It now gets past the original `devenv` exec failure.
- It fails later because Elixir tooling is not installed in this runtime (`mix` not available outside wrapper).

So the original deterministic failure is fixed at the script level; remaining failure is environmental (missing Elixir toolchain in this container).