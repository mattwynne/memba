# Iteration Plan Review: 001 Member Message Deliverability

## Decision: NOT READY

## Confidence: Medium

The plan has a sound high-level direction and appropriately minimal scope (domain model only, fake provider, no UI). However, critical specification gaps would force implementers to make significant product and domain decisions during coding, increasing risk of rework.

## Blocking Gaps

1. **Missing Cucumber scenarios**: The shared feature file content is not included or referenced. We cannot verify that acceptance criteria are actually testable or that the scenarios cover the stated requirements. The plan's primary validation mechanism is invisible.

2. **Unresolved domain modeling decision**: The plan explicitly defers deciding "whether `opened` should be represented as a delivery status, a separate receipt event, or both" to implementation time. This is a core domain model design choice that affects aggregate structure, event naming, and projection logic—the heart of this iteration.

3. **No concrete module/schema specifications**: The implementation plan lists high-level tasks but provides no specific:
   - Command/event/aggregate names (e.g., `SendMessageToClub`, `MessageSent`, `DeliveryStatusChanged`)
   - Projection table schemas or fields
   - Fake provider interface/behavior contract
   - Module paths or file organization

4. **Undefined minimal data model**: What exactly is a "club," "person," or "membership" in this minimal slice? Required attributes for each are not specified. Without this, implementers cannot build the aggregates or projections.

5. **Missing business rule**: Who can send messages to a club's membership? The plan marks permissions as a non-goal but doesn't specify whether *any* member can send, or if there's a role/permission check. This is fundamental to the command handler logic.

## Non-blocking Improvements

1. **Edge case coverage**: Acceptance criteria don't address empty clubs, duplicate memberships, sending the same message twice, or person-is-member-of-multiple-clubs scenarios.

2. **Error state handling**: No acceptance criteria for invalid commands (e.g., sending to non-existent club, non-member trying to send).

3. **Idempotency strategy**: No mention of command deduplication or handling duplicate webhook deliveries from the fake provider.

4. **Projection update strategy**: Should projections rebuild from events or use projection versioning? How should conflicts be handled?

5. **Test data setup**: No guidance on how to set up test clubs/people/memberships for Cucumber scenarios or whether factory/fixture patterns should be used.

6. **Fake provider specifics**: The interface contract for the fake email provider port is not specified (methods, arguments, return values, state tracking).

## Smallest Viable Iteration

The current scope is already appropriately minimal. Do not reduce further. Instead, add specification detail:

**Keep:**
- Event-sourced domain model only (no Phoenix UI)
- Fake email provider
- Both member-facing and operator-facing projections
- Cucumber scenarios as primary validation

**Recommended sub-slicing approach** (if blocking gaps cannot be resolved quickly):
1. First PR: Event store setup + club/person/membership aggregates + "send message" command
2. Second PR: Delivery status tracking + fake provider + projections
3. Third PR: Cucumber scenarios + domain test layer

But this sub-slicing is less important than resolving the specification gaps.

## Required Plan Edits

### 1. Add Cucumber Scenario Examples (or reference)

Either inline 3-5 representative scenarios from the shared feature file or add:

```markdown
## Representative Scenarios

See `features/member-message-deliverability.feature` for full specification.

Example scenario:
```gherkin
Scenario: Member sends message and sees delivery status
  Given a club "Mountain Bikers" exists
  And "Alice" is a member of "Mountain Bikers"
  And "Bob" is a member of "Mountain Bikers"
  When "Alice" sends message "Ride on Sunday?" to "Mountain Bikers" members
  Then the message is sent to "Bob"
  And "Alice" sees status "sent" for the message
  When the fake provider reports delivery to "Bob"
  Then "Alice" sees status "delivered" for the message
```
```

### 2. Specify Core Domain Model

Add to the plan:

```markdown
## Domain Model Specification

**Aggregates:**
- `Club` (id, name, created_at)
  - Commands: `CreateClub`
  - Events: `ClubCreated`
  
- `Person` (id, email, display_name)
  - Commands: `CreatePerson`
  - Events: `PersonCreated`
  
- `Membership` (club_id, person_id)
  - Commands: `AddMemberToClub`
  - Events: `MemberAddedToClub`
  
- `ClubMessage` (id, club_id, sender_person_id, subject, body, sent_at)
  - Commands: `SendMessageToClubMembers`
  - Events: `MessageSentToClubMembers`, `MessageDeliveryStatusChanged`, `MessageReceiptRecorded`
  
**Decision: `opened` status**
Resolve now: `opened` will be recorded as a `MessageReceiptRecorded` event (separate from delivery statuses) but projected as a simple status value in the member-facing view.

**Projection Schemas:**
- `club_messages` table: id, club_id, sender_person_id, subject, body, sent_at
- `message_deliveries` table: id, message_id, recipient_person_id, delivery_status (sent/delivered/bounced/delayed), status_at
- `message_receipts` table: id, delivery_id, receipt_type (opened), received_at
- `member_message_summaries` (read model): message_id, sender_name, recipient_count, simple_status (sent/delivered/bounced/opened), status_at
- `deliverability_details` (read model): message_id, delivery_id, recipient_email, all_statuses_json, timeline_json
```

### 3. Specify Fake Provider Interface

Add:

```markdown
## Fake Email Provider Port

**Module:** `Memba.Messaging.EmailProvider` (behaviour)
**Fake implementation:** `Memba.Messaging.FakeEmailProvider`

**Interface:**
```elixir
@callback send_message(recipient_email :: String.t(), subject :: String.t(), body :: String.t(), metadata :: map()) ::
  {:ok, provider_message_id :: String.t()} | {:error, reason :: atom()}

@callback simulate_delivery_status_change(provider_message_id :: String.t(), new_status :: atom()) ::
  :ok | {:error, :not_found}
```

**Fake behavior:**
- `send_message/4` returns `{:ok, random_uuid}` immediately
- `simulate_delivery_status_change/2` triggers callback to domain service that issues `RecordDeliveryStatusChange` command
- Stores sent messages in ETS for test inspection
```

### 4. Clarify Permission Model

Add to acceptance criteria or business decisions:

```markdown
**Business Rule (minimal for this iteration):**
Any member of a club can send a message to that club's membership. Permission/role validation is a non-goal for this iteration but will be addressed when building the Phoenix UI layer.

**Acceptance criterion:**
8. Sending command must include sender_person_id and club_id. Command handler verifies sender is a member of the club before proceeding.
```

### 5. Add Implementation Specifics

Expand implementation plan step 3:

```diff
- 3. Define the initial commands/events/aggregates for:
-    - creating a club;
-    - creating a person;
-    - adding a person as a club member;
-    - sending a message to club members;
-    - recording delivery status changes: sent, delivered, delayed, bounced, spam complaint, opened.
+ 3. Define the initial commands/events/aggregates:
+    - `Memba.Clubs.Commands.CreateClub` → `Memba.Clubs.Events.ClubCreated`
+    - `Memba.Clubs.Commands.CreatePerson` → `Memba.Clubs.Events.PersonCreated`
+    - `Memba.Clubs.Commands.AddMemberToClub` → `Memba.Clubs.Events.MemberAddedToClub`
+    - `Memba.Messaging.Commands.SendMessageToClubMembers` → `Memba.Messaging.Events.MessageSentToClubMembers`
+    - `Memba.Messaging.Commands.RecordDeliveryStatusChange` → `Memba.Messaging.Events.DeliveryStatusChanged`
+    - `Memba.Messaging.Commands.RecordMessageReceipt` → `Memba.Messaging.Events.MessageReceiptRecorded`
+    - Aggregates: `Memba.Clubs.Club`, `Memba.Clubs.Person`, `Memba.Clubs.Membership`, `Memba.Messaging.ClubMessage`
```

## Validation Plan

After the above edits are made:

1. **Re-review the plan**: Verify all blocking gaps are resolved and acceptance criteria are now testable.

2. **Verify Cucumber scenarios exist**: Confirm the shared feature file contains scenarios covering:
   - Creating clubs and adding members
   - Sending message to club members
   - Each delivery status transition (sent, delivered, bounced, delayed)
   - Recording opens
   - Member-facing simple status projection
   - Operator-facing detailed deliverability projection

3. **Implementation validation**: After implementation, success is proven when:
   - All Cucumber scenarios pass using `huddlz-hq/cucumber` against the Elixir domain model
   - ExUnit tests cover edge cases (empty clubs, non-member sending, invalid commands)
   - `devenv shell mix precommit` passes with no warnings
   - Manual REPL inspection can demonstrate: create club → add members → send message → simulate deliveries → query projections → see expected data

4. **Stop condition**: All acceptance criteria have passing Cucumber scenarios, all ExUnit tests pass, precommit hook passes, and the team can demonstrate the full flow in `iex -S mix`.

---

**Summary**: Resolve the six blocking gaps above (scenarios, domain model spec, provider interface, permission rule, implementation module names, and the `opened` status decision), then this plan will be ready for implementation. The scope itself is appropriate.