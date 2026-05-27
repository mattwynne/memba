# Iteration Plan Review: 001-member-message-deliverability

**Decision:** NOT READY  
**Confidence:** High

## Blocking Gaps

1. **Goal/Scope Contradiction**: The goal states "the operator can see detailed deliverability information and club members can see simplified receipt status" but implementation step 16 explicitly says "do not implement the Phoenix UI layer in this iteration". How will operators and members "see" this information without a UI? The goal and scope are fundamentally misaligned.

2. **Missing Acceptance Criteria in Plan**: The plan references external Cucumber feature files at `acceptance-tests/features/**/*.feature` as the specification, but these files are not included, excerpted, or summarized in the plan. I cannot validate whether the acceptance criteria are complete, testable, or aligned with the goal without seeing them. The plan must include or summarize the key scenarios.

3. **Unresolved Technical Decisions Listed in Plan**: The "Open Technical Decisions" section explicitly states that package versions and folder structure are TBD. These are foundational implementation details that must be resolved before work begins, not during implementation.

4. **No Database/Migration Plan**: EventStore requires either a separate database or migration scripts. The plan does not specify:
   - Whether EventStore uses its own database or shares Ecto's database
   - What migrations are needed
   - How EventStore schema initialization works
   - Whether projections use the same database

5. **No Module/Namespace Structure**: Steps mention "Membership aggregates" and "Message aggregate" but don't specify:
   - Module naming (e.g., `MembaAgent.Membership.Aggregates.Club`?)
   - Where command/event modules live
   - How the query API is structured
   - Where projector modules go

6. **Vague Implementation Steps**: Step 9 says "implement SendMessage so the application service resolves recipients" but doesn't specify:
   - What is the "application service"? A module? A process?
   - Where does this resolution happen?
   - How are errors handled if resolution fails?

## Non-blocking Improvements

1. **ADR Summary Missing**: The plan references ADRs 0004, 0005, 0006, 0011, 0012 but doesn't summarize the key decisions that affect this iteration. For example, what exactly is "the member-facing mapping from ADR 0006"?

2. **No Error Handling Strategy**: The plan doesn't specify how errors are handled:
   - What if no recipients are resolved?
   - What if the fake provider fails?
   - What if status transitions are invalid?
   - Are these aggregate validation errors, or application-level errors?

3. **No Test Organization Plan**: Beyond "add ExUnit tests" and "use Cucumber", there's no guidance on:
   - Test file structure
   - What gets Cucumber coverage vs ExUnit coverage
   - How to organize aggregate tests vs projection tests vs integration tests

4. **Unclear Stop Condition**: What does "domain skeleton" mean precisely? The plan says we'll "be able to model" things but doesn't specify whether:
   - All CRUD operations must work
   - All status transitions must be implemented
   - Query APIs must be complete
   - Or just the happy path works

## Smallest Viable Iteration

**Recommended minimal slice for iteration 001:**

**Goal:** Prove event sourcing infrastructure works with one simple domain operation.

**Scope:**
1. Add EventStore + Commanded dependencies with specific versions
2. Configure EventStore database/migrations
3. Implement one minimal aggregate: `Message` with two commands:
   - `SendMessage` (with hardcoded single recipient, no Membership dependency)
   - `RecordDeliveryStatus` (accepting one status: "delivered")
4. Implement one projection: message list with ID, content, timestamp
5. Write ExUnit tests for aggregate + projection
6. Document the working EventStore/Commanded setup

**Out of scope:**
- Membership aggregate (add in iteration 002)
- Complex state machine (add in iteration 003)
- Cucumber integration (add in iteration 004)
- Multiple recipients, status transitions, fake provider

**Success criteria:**
- `mix test` passes
- Can create a message event and query it back from projection
- EventStore is persisting events correctly
- Documented pattern for future aggregates

This validates the infrastructure and establishes patterns before building complex domain logic.

## Required Plan Edits

### 1. Resolve Goal/Scope Contradiction

**Current:** Goal says operators/members "can see" but scope excludes UI.

**Required edit:** Either:
- **Option A:** Change goal to: "Define and implement the event-sourced domain model for Membership and Messaging, including per-recipient delivery status, so that future UI layers can query detailed deliverability and receipt information."
- **Option B:** Add a minimal UI read-only view to actually demonstrate "seeing" the information.

Choose one and update both the goal and scope consistently.

### 2. Include or Summarize Acceptance Criteria

**Required edit:** Add a new "Acceptance Criteria" section that either:
- Includes the complete Cucumber scenarios inline, OR
- Provides a detailed summary of scenarios covering:
  - Happy path: send message, multiple recipients receive, status updates work
  - Edge cases: no recipients, duplicate status reports, invalid transitions
  - Queries: operators can query delivery details, members can query receipts
  - Error cases: resolution fails, invalid status transitions

Without this, the plan cannot be validated.

### 3. Resolve Technical Decisions

**Required edit:** Replace "Open Technical Decisions" section with resolved decisions:

```markdown
## Technical Decisions

- EventStore: use `eventstore` version X.Y.Z
- Commanded: use `commanded` version X.Y.Z
- Adapter: use `commanded_eventstore_adapter` version X.Y.Z
- Projections: use `commanded_ecto_projections` version X.Y.Z
- Cucumber: use `huddlz-hq/cucumber` at commit SHA or tag
- EventStore database: [separate database / shared with Ecto]
- Folder structure:
  - `/lib/memba_agent/membership/` - Membership context
    - `aggregates/` - Club, Person, Membership aggregates
    - `commands/` - Command modules
    - `events/` - Event modules
  - `/lib/memba_agent/messaging/` - Messaging context
    - `aggregates/` - Message aggregate
    - `commands/`, `events/`
  - `/test/support/cucumber/` - Cucumber step definitions
```

### 4. Add Database/Migration Plan

**Required edit:** Add to implementation steps:

```markdown
2. Configure EventStore:
   - Add `config/event_store.exs` with database configuration
   - Run EventStore init task: `mix do event_store.create, event_store.init`
   - Add EventStore supervision to application.ex
   
3. Configure Commanded:
   - Add Commanded.Application module at `lib/memba_agent/commanded_app.ex`
   - Register event store adapter
   - Add Commanded supervisor to application.ex
```

### 5. Add Module Structure Details

**Required edit:** Update steps 6, 8, and 13 to be specific:

```markdown
6. Implement Membership context at `lib/memba_agent/membership/`:
   - Aggregates: `Aggregates.Club`, `Aggregates.Person`, `Aggregates.Membership`
   - Commands: `Commands.CreateClub`, `Commands.CreatePerson`, `Commands.AddMembership`
   - Events: `Events.ClubCreated`, `Events.PersonCreated`, `Events.MembershipAdded`
   
7. Implement Membership projections:
   - Projection module: `Projections.MembershipProjector`
   - Ecto schema: `Projections.ActiveMembership` with fields: club_id, person_id, person_name, person_email, added_at
   - Migration: `priv/repo/migrations/*_create_membership_projections.exs`
   - Query API: `Membership.list_active_members(club_id)` calls projection, not aggregate

8. Implement Messaging context at `lib/memba_agent/messaging/`:
   - Aggregate: `Aggregates.Message` (one per message)
   - Commands: `Commands.SendMessage`, `Commands.RecordDeliveryStatus`
   - Events: `Events.MessageSent`, `Events.DeliveryStatusRecorded`
```

### 6. Specify Validation Success Criteria

**Required edit:** Replace vague "Validation Plan" with concrete checklist:

```markdown
## Validation Plan

Success criteria:
- [ ] All Cucumber scenarios in `acceptance-tests/features/member-message.feature` pass
- [ ] All Cucumber scenarios in `acceptance-tests/features/operator-deliverability.feature` pass
- [ ] ExUnit tests for Message aggregate state machine pass (minimum 20 test cases)
- [ ] ExUnit tests for projection updates pass
- [ ] `mix precommit` passes with no warnings
- [ ] Can manually execute in `iex -S mix`:
  ```elixir
  # Create club
  {:ok, club_id} = Membership.create_club("Test Club")
  
  # Add members
  {:ok, _} = Membership.add_member(club_id, "Alice", "alice@example.com")
  {:ok, _} = Membership.add_member(club_id, "Bob", "bob@example.com")
  
  # Send message
  {:ok, message_id} = Messaging.send_message(club_id, sender_id, "Hello!")
  
  # Query deliveries
  deliveries = Messaging.list_deliveries(message_id)
  assert length(deliveries) == 2
  
  # Update status
  {:ok, _} = Messaging.record_status(message_id, recipient_id, "delivered")
  ```

Stop condition: All checkboxes checked.
```

## Validation Plan for This Review

To validate that the iteration plan is truly ready after edits:

1. **Re-read the edited plan** and confirm:
   - Goal and scope are aligned (no contradictions)
   - Acceptance criteria are included and complete
   - All technical decisions are resolved
   - Module structure is specified
   - Database/migration plan is clear

2. **Cross-check with ADRs** mentioned (0004, 0005, 0006, 0011, 0012):
   - Verify the plan implements the decisions correctly
   - Verify no conflicting decisions exist

3. **Validate acceptance criteria** by asking:
   - Do they cover the "happy path" of sending a message?
   - Do they cover important edge cases (no recipients, duplicate status, invalid transition)?
   - Do they cover both member and operator views?
   - Are they objectively testable (no ambiguous terms)?

4. **Check for smallest viable scope** by asking:
   - Can any steps be moved to iteration 002 without losing value?
   - Is each step necessary for the stated goal?
   - Are we proving one thing at a time, or trying to build everything?

5. **Verify stop condition** is clear:
   - A developer should be able to read the validation plan and know exactly when to stop
   - No ambiguous terms like "skeleton" or "minimal" without definition
   - Concrete checklist or demo script exists

**The plan is ready when:** Someone unfamiliar with the codebase could implement it based solely on the plan text, without needing to ask clarifying questions about goals, scope, structure, or success criteria.