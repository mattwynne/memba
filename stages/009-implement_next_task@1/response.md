1. **Selected todo line**
   - `- [ ] 001 Inspect current identity, auth-token, Person email-address, and staff edit flows before changing the model.`

2. **Changes made**
   - Added `docs/iterations/053-my-settings-email-addresses/task-001-inspection.md`.
   - The inspection documents:
     - current signed-in identity/session flow;
     - auth sign-in token and auth-email request storage/semantics;
     - Person email-address aggregate/events/projections/query APIs;
     - staff Person create/edit flows;
     - inbound sender identity resolution;
     - existing test footholds and implementation implications for later tasks.

3. **Focused validation**
   - Ran `git diff --check` before and after todo check-off.
   - Result: passed both times with no whitespace errors.
   - Did not run `dev check` because this task was docs/inspection-only and did not change executable code, config, tests, migrations, UI, routing, or app behaviour.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Inspect current identity, auth-token, Person email-address, and staff edit flows before changing the model.`
   - To:
     - `- [x] 001 Inspect current identity, auth-token, Person email-address, and staff edit flows before changing the model.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and incorporated plan-referenced ADRs:
     - ADR 0015: later `/my/settings` should be LiveView.
     - ADR 0023: later tabs should be URL-addressable LiveView state.
   - Also inspected nearby/relevant ADRs:
     - ADR 0021 for committed read-model change PubSub.
     - ADR 0022 for projection barriers.
   - Inspection notes explicitly call out how those constraints apply to later implementation tasks.