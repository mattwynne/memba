1. **Selected todo line**
   - `- [ ] 001 Inspect current outbound send paths and tests:`

2. **Changes made**
   - Added inspection notes at:
     - `docs/iterations/038-email-delivery-handoff-boundary/task-001-inspection.md`
   - Documented:
     - current synchronous `send_club_message/2` → `deliver_to_provider/1` → `EmailDeliveryProvider.deliver/1` path
     - browser compose and accepted inbound-email callers
     - `EmailDelivery`, member-facing, and staff-facing projection behaviour
     - provider seams for Fake, Local, Postmark, Resend, and test Unavailable provider
     - tests that currently encode synchronous provider delivery and `sent` initial statuses
     - ADR conformance notes for follow-up implementation tasks

3. **Focused validation**
   - Ran:
     - `git diff --check`
   - Result: passed with no whitespace errors.
   - Did not run `dev check` because this task was inspection/docs-only and did not change code, config, migrations, tests, or executable examples.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 Inspect current outbound send paths and tests:`
   - To:
     - `- [x] 001 Inspect current outbound send paths and tests:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspected relevant accepted ADRs:
     - ADR 0002 Commanded/CQRS workflows
     - ADR 0004 message deliverability as message aggregate
     - ADR 0005 resolved recipients in send commands
     - ADR 0006 simplified member-facing delivery status
     - ADR 0007 separate Membership and Messaging contexts
     - ADR 0009 Commanded Ecto projections
     - ADR 0016 switchable Postmark/Resend providers
     - ADR 0021 committed read-model change PubSub
     - ADR 0022 projection barriers
   - Captured conformance notes in the inspection document for subsequent implementation tasks.