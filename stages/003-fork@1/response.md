# Iteration Plan Review: 001-member-message-deliverability

## Decision: NOT READY

## Confidence: Medium

The plan demonstrates strong technical thinking and a clear architectural approach. The event-sourcing design is coherent, the domain model is well-reasoned, and the validation strategy using shared Cucumber scenarios is sound. However, several critical implementation details are underspecified, and the acceptance criteria are referenced but not shown in the plan document itself.

---

## Blocking Gaps

1. **Missing acceptance criteria**: The plan references `acceptance-tests/features/member_message_deliverability.feature` and `acceptance-tests/features/operator_email_deliverability.feature` but these files aren't shown in the plan. Without seeing the actual scenarios, we cannot validate that the implementation steps will satisfy them.

2. **Process manager/handler pattern underspecified**: Step 5 mentions "Use a one-shot Commanded handler to emit CreateDelivery for each recipient from MessageSent handler." This is a critical architectural component but it's unclear:
   - Is this a Commanded process manager?
   - A projector that emits commands?
   - A synchronous handler in the aggregate?
   - How does it access the membership projection to determine recipients?
   - What happens if it fails partway through creating deliveries?

3. **Database setup lifecycle unclear**: Step 3 says "Create the event-store database" but doesn't specify:
   - Manual SQL script?
   - Mix task?
   - Ecto migration?
   - devenv initialization script?
   - What about the EventStore event-streams schema initialization?

4. **Projection infrastructure underspecified**: Step 8 defines projection schemas but doesn't explain:
   - How projectors are registered with Commanded
   - Where projector modules live
   - How they handle errors or event replay
   - How they're tested independently
   - Migration file details for the read-model tables

5. **Email provider port interface undefined**: Step 7 mentions a "fake/stub email-provider port" but doesn't specify:
   - The port's module name or interface contract
   - Where the port behavior is defined
   - How it's injected into the application service
   - What the success/failure responses look like

---

## Non-Blocking Improvements

1. **Goal statement**: Rewrite to emphasize user/operator capability rather than technical implementation. Example: "Enable club administrators to track message delivery status and operators to diagnose email deliverability issues using event-sourced domain model with fake provider."

2. **Sequence clarity**: Add a brief sequence diagram or numbered flow showing: command → aggregate → event → handler/PM → delivery commands → delivery aggregate → events → projectors → queries.

3. **Migration naming**: Specify migration file names in step 8, e.g., `priv/repo/migrations/20240115_create_clubs.exs`.

4. **Test file organization**: Clarify where Cucumber step definitions live (e.g., `test/acceptance/step_definitions/`), where ExUnit tests live, and the naming pattern.

5. **Error handling scope**: Briefly state how aggregate command failures, projection failures, and fake provider failures should behave in this iteration.

6. **Dependency injection pattern**: Specify how the fake provider is configured/injected for tests vs. real provider in later iterations (Application config? Start argument? Behaviour + implementation swap?).

7. **Concurrency assumptions**: State assumptions about concurrent message sends, delivery status updates, and projection consistency requirements (or explicitly defer to later iteration).

---

## Smallest Viable Iteration

The current plan could be split into two smaller iterations:

**Iteration 1A** (Event-sourced message core):
- Add Commanded and EventStore infrastructure
- ClubMessage aggregate only (SendMessage command, MessageSent event)
- Basic projections: `clubs`, `people`, `memberships`, `messages` (no deliveries yet)
- ExUnit aggregate tests
- Manual verification via `iex` console
- Outcome: Can model sending a message, query sent messages

**Iteration 1B** (Deliverability tracking):
- Delivery aggregate and status tracking
- `deliveries` projection and queries
- Process manager/handler for delivery creation
- Fake email provider port
- Cucumber acceptance tests
- Outcome: Full deliverability tracking with scenarios validated

However, the current single iteration is defensible if:
- The shared Cucumber scenarios already exist and are the source of truth
- The team values validating the entire domain model in one coherent slice
- The timeline permits 1-2 weeks of focused implementation

**Recommendation**: Keep as single iteration but address blocking gaps first.

---

## Required Plan Edits

Make these specific changes to the plan document:

1. **Add acceptance criteria section** after the goal:
   ```markdown
   ## Acceptance Criteria
   
   This iteration satisfies the scenarios in:
   - `acceptance-tests/features/member_message_deliverability.feature`
   - `acceptance-tests/features/operator_email_deliverability.feature`
   
   Key scenarios include:
   [Paste the actual Gherkin scenarios here, or at minimum list the scenario names]
   ```

2. **Clarify step 5** in the implementation plan:
   ```markdown
   5. Define the `ClubMessage` aggregate:
      - Module: `Memba.Messaging.Aggregates.ClubMessage`
      - Command: `SendMessage{club_id, sender_person_id, subject, body, sent_at, recipient_person_ids}`
      - Event: `MessageSent{message_id, club_id, sender_person_id, subject, body, sent_at, recipient_person_ids}`
      - Validations: non-empty subject/body, sender is member, recipients are active members, club exists
      - Command handler publishes `MessageSent` event
      - Create a Commanded event handler module `Memba.Messaging.DeliveryCreationHandler` that:
        - Subscribes to `MessageSent` events
        - Emits one `CreateDelivery` command per recipient_person_id
        - Uses the memberships/people projections to look up recipient emails
        - Runs transactionally per message (all deliveries created or none)
   ```

3. **Clarify step 3**:
   ```markdown
   3. Create the event-store database:
      - Add `mix tasks.eventstore.create` task or manual PostgreSQL script
      - Run EventStore schema initialization: `mix event_store.create`
      - Document the setup command in README or devenv shell hook
      - Alternative: Add ecto migration that initializes event_store schema
   ```

4. **Expand step 7**:
   ```markdown
   7. Define the email provider port and fake implementation:
      - Behavior module: `Memba.Messaging.Ports.EmailProvider`
      - Function: `send_email(recipient_email, subject, body, metadata) -> {:ok, provider_message_id} | {:error, reason}`
      - Fake implementation: `Memba.Messaging.Ports.FakeEmailProvider`
        - Always returns `{:ok, "fake-msg-#{unique_id}"}`
        - Stores sent messages in Agent/ETS for test assertions
      - Inject via Application config: `config :memba, email_provider: Memba.Messaging.Ports.FakeEmailProvider`
   ```

5. **Expand step 8** with migration and projector details:
   ```markdown
   8. Build Ecto projections/read models:
      - Migration: `priv/repo/migrations/20240115000000_create_messaging_projections.exs`
        - Tables: `clubs`, `people`, `memberships`, `messages`, `deliveries`
        - Indexes: `messages.club_id`, `deliveries.message_id`, `memberships.{club_id, person_id}`
      - Projector modules in `lib/memba/messaging/projectors/`:
        - `ClubProjector` (handles ClubCreated)
        - `PersonProjector` (handles PersonCreated)
        - `MembershipProjector` (handles MemberAdded)
        - `MessageProjector` (handles MessageSent, updates from DeliveryCreated)
        - `DeliveryProjector` (handles DeliveryCreated, DeliveryStatusRecorded)
      - Register projectors in Commanded router config
      - Query modules in `lib/memba/messaging/queries/`:
        - `MemberReceipt.list_for_message(message_id)` - returns simplified status list
        - `OperatorDeliverability.list_for_message(message_id)` - returns detailed status list
   ```

6. **Add to "Open Technical Decisions" section**:
   ```markdown
   - Process manager error-handling strategy: should delivery creation failures fail the entire message send or allow partial delivery creation? (Recommend: all-or-nothing for this iteration)
   - Projection consistency guarantees: are eventually-consistent projections acceptable or do queries need read-after-write consistency? (Recommend: eventually-consistent for this iteration)
   ```

---

## Validation Plan

To prove this iteration succeeded:

1. **Scenario validation**:
   - All scenarios in `member_message_deliverability.feature` pass when run via `huddlz-hq/cucumber` against the domain model with fake provider
   - All scenarios in `operator_email_deliverability.feature` pass similarly
   - Scenarios run in under 5 seconds total (fast feedback)

2. **Domain model validation**:
   - ExUnit tests for aggregate command validation (invalid transitions, missing data, etc.) all pass
   - ExUnit tests for duplicate delivery status idempotence pass
   - ExUnit tests for projection updates pass
   - Run `mix test` - all tests green

3. **Query validation**:
   - Can query member receipt status after sending message (simplified: sent/delivered/problem/opened)
   - Can query operator deliverability view with provider-style details
   - Queries return expected data for multi-recipient messages with mixed statuses

4. **Infrastructure validation**:
   - Can run `mix event_store.reset` and `mix ecto.reset` to rebuild from scratch
   - Event store accumulates events correctly (no duplicate events from retries)
   - Projections rebuild correctly from event replay
   - `devenv shell mix precommit` passes with no warnings

5. **Integration validation**:
   - Fake provider stores sent emails for test inspection
   - Can send message via command, verify MessageSent event, verify deliveries created, verify projections updated - all in one test
   - Process manager creates correct number of delivery commands (one per recipient)

**Stop condition**: All Cucumber scenarios pass, all ExUnit tests pass, precommit clean, and you can demonstrate in `iex`:
```elixir
# Send message
{:ok, message_id} = Memba.Messaging.send_message(club_id, sender_id, "Subject", "Body")

# Query receipt
Memba.Messaging.Queries.MemberReceipt.list_for_message(message_id)
# => [%{recipient: "Alice", status: :sent}, ...]

# Query deliverability
Memba.Messaging.Queries.OperatorDeliverability.list_for_message(message_id)
# => [%{recipient_name: "Alice", recipient_email: "alice@...", status: :sent, ...}, ...]
```

---

**Summary**: The plan's architectural approach is sound and the scope is coherent, but critical implementation patterns (process manager, projection setup, database initialization, provider port) need detailed specification before implementation begins. Incorporate the required edits above and this becomes a strong, implementation-ready plan.