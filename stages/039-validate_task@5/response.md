### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Read `/tmp/fabro-pre-validate-snapshot.md`; it records clean status at implementation checkpoint `668f8a9`.
  - Live `git status --short` is clean.
  - Recent log shows `1d96d99` pre-validation checkpoint on top of `668f8a9` implementation checkpoint.
  - `git show 668f8a9 -- docs/iterations/035-obliterate-opened-delivery-status/todo.md` shows exactly one ordinary task changed:
    - `005 Keep events/email_delivery_opened.ex as the deserialization tombstone with a deprecation comment.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state confirms task `005` was the first unchecked task when implementation started.

- Implementation artifacts found:
  - `web/lib/memba/messaging/events/email_delivery_opened.ex` moduledoc was changed from active “opened” event language to an explicit historic deserialization tombstone/deprecated replay shim.
  - The event struct remains intact for historic event-store deserialization.
  - No acceptance `*.feature` files were changed.

- Tests run/results found:
  - Live validation run:
    - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging/events/email_delivery_opened.ex` — passed.
    - `PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors` — passed.
  - `git show --check 668f8a9` passed.

- ADR/plan conformance notes:
  - Work matches plan item `005` and stays within scope.
  - The change preserves replay safety by retaining the historic event module while documenting it as replay-only.
  - No active opened-status behavior was reintroduced.
  - Todo changes did not split, reorder, delete, weaken, or defer plan-required work.

{"context_updates":{"task_valid":true,"task_retry_available":false}}