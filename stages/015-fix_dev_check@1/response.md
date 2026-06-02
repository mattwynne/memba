Implemented a focused fix for the reproducible dev-check failure.

## 1. Dev check failure addressed

### Failure
`MembaWeb.AuthControllerTest`

- Test: `staff onboarding LiveView creates a person record for first-time staff and redirects to the staff area`
- Symptom: `Membership.create_person(..., consistency: :strong)` returned `{:error, :consistency_timeout}`
- Repro: full ExUnit suite with seed `734908`

### Root cause
The reduced reproduction showed `Memba.EventSourcedSetupTest` was directly truncating shared EventStore/projection storage via `reset_event_sourced_storage!/0` while Commanded projector subscriptions remained running.

That left later strong-consistency dispatches waiting for projector acknowledgements that never arrived.

## 2. Changes made

### Failure-to-fix mapping

| Failure | Fix | Files/modules |
|---|---|---|
| AuthController staff onboarding consistency timeout after event-sourced setup tests | Added a safe event-sourced reset helper that stops projectors, resets storage, clears Commanded subscription ack caches, and restarts projectors | `web/test/support/event_sourced_case.ex` |
| Event-sourced setup tests leaving shared projector/subscription state incoherent | Switched direct setup-test resets to the new safe helper | `web/test/event_sourced_setup_test.exs` |

## 3. Files changed

### Event-sourced test isolation
- `web/test/support/event_sourced_case.ex`
  - Added `reset_event_sourced_system!/0`
  - Added reset of Commanded subscription acknowledgement caches for:
    - `Memba.Membership.App`
    - `Memba.Messaging.App`
  - Also clears subscription ack cache during normal `EventSourcedCase` setup reset.

- `web/test/event_sourced_setup_test.exs`
  - Replaced direct calls to `reset_event_sourced_storage!/0` with `reset_event_sourced_system!/0`.

No acceptance feature files were modified.

## 4. Tests run

### Reduced reproduction
```sh
PATH="$PWD/bin:$PATH" devenv shell -O services.postgres.port:int "${MEMBA_POSTGRES_PORT:-15432}" -- \
  bash -lc 'cd web && mix test test/event_sourced_setup_test.exs test/memba_web/controllers/auth_controller_test.exs --seed 734908 --max-failures 1'
```

Result:

- Passed
- `23 tests, 0 failures`

### Full ExUnit with originally failing seed
```sh
PATH="$PWD/bin:$PATH" devenv shell -O services.postgres.port:int "${MEMBA_POSTGRES_PORT:-15432}" -- \
  bash -lc 'cd web && mix test --seed 734908'
```

Result:

- Passed
- `380 tests, 0 failures`

### Required full gate
```sh
PATH="$PWD/bin:$PATH" dev ci
```

Result:

- Passed
- `380 tests, 0 failures`

## 5. Remaining failures or questions

None.

Working tree has the two intended tracked test-support changes plus existing untracked `.fabro/tmp/` artifacts.