1. **Selected todo line**
   - `004 Reduce the aggregate apply/2 for EmailDeliveryOpened to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.`

2. **Changes made**
   - `web/lib/memba/messaging/message.ex`
     - Changed `apply/2` for `%EmailDeliveryOpened{}` from updating delivery state to `:delivered` into a documented replay-only no-op returning the aggregate unchanged.
   - `web/lib/memba/messaging/projectors/member_email_delivery.ex`
     - Changed `%EmailDeliveryOpened{}` projection from updating member read models to `"delivered"` into a documented no-op projection that only advances projector checkpoints.
   - `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
     - Changed `%EmailDeliveryOpened{}` projection from updating staff read models to `"delivered"` into a documented no-op projection that only advances projector checkpoints.
   - Updated focused aggregate/projector tests:
     - `web/test/memba/messaging/message_test.exs`
     - `web/test/memba/messaging/member_email_delivery_projection_test.exs`
     - `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
   - The projector tests now assert historic opened events leave read models unchanged while still recording projection progress.

3. **Focused validation**
   - Red run after updating focused tests, before production changes:
     - `env -u PGHOST -u PGPORT -u DEVENV_RUNTIME devenv shell -- bash -lc 'cd web && MIX_ENV=test mix test test/memba/messaging/message_test.exs test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs'`
     - Result: failed as expected with 3 failures showing the old aggregate/projector active behaviour still mapped opened to delivered.
   - Green focused run after implementation:
     - Same command.
     - Result: `26 tests, 0 failures`.
   - Formatting:
     - `env -u PGHOST -u PGPORT -u DEVENV_RUNTIME devenv shell -- bash -lc 'cd web && mix format --check-formatted ...'`
     - Result: passed.
   - Whitespace:
     - `git diff --check`
     - Result: passed.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Output included existing/pending opened-related UI test failures that are covered by later todo task `006`; I did not broaden this task to fix those.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Reduce the aggregate ...`
   - To:
     - `- [x] 004 Reduce the aggregate ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Preserves ADR 0002 / event-sourcing expectations by keeping historic event replay safe.
   - Preserves ADR 0009 by using Commanded Ecto projector machinery so no-op historic events still advance projection checkpoints.
   - Preserves CQRS/read-model boundaries: command routing and query APIs were not changed; only aggregate replay and projector replay behaviour changed.
   - ADR 0012’s former opened-tracking behaviour is being retired by the approved iteration plan; this task removes active opened behaviour while keeping the replay shim required by event history compatibility.