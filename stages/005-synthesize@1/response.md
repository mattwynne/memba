# Final Readiness Review: Iteration 001 – Member Message Deliverability

## 1. Decision: NOT READY

## 2. Confidence: High

All three reviewers converged on the same core finding: the plan is well-structured and thorough but contains several material gaps that would force an implementing engineer to make product or technical design decisions that should be made in the plan.

## 3. Consensus Findings

- **Aggregate identity strategy is unspecified.** The plan defines commands routed to aggregates (Club, Person, Messaging) but never specifies how aggregate IDs are generated or what the stream naming convention is. All three reviewers flagged this.
- **Commanded application module and router configuration are missing.** The plan doesn't specify whether there is one Commanded application or multiple, how the router maps commands to aggregates, or how the event store is configured (e.g., `Commanded.EventStore.Adapters.EventStore` schema/prefix). All three reviewers flagged this.
- **The Messaging aggregate's responsibility boundary is ambiguous.** It's unclear whether there is one Messaging aggregate per club, per message, or per delivery. The plan defines `SendMessage` and `RecordDeliveryStatus` on "the Messaging aggregate" but doesn't define the aggregate's identity or stream. Two of three reviewers flagged this as blocking.
- **Process manager / event handler for delivery creation is unspecified.** The plan says `MessageSent` triggers `DeliveryCreated` events (one per recipient), but doesn't say what component does this — is it a process manager, an event handler, or part of the aggregate? All three reviewers flagged this.
- **Projector implementation approach is unspecified.** The plan lists Ecto read-model schemas but doesn't say whether projections use `Commanded.Projections.Ecto` or custom `Commanded.Event.Handler` modules. Two reviewers flagged this.
- **Cucumber package identity and configuration are underspecified.** The plan references `huddlz-hq/cucumber` but the exact package name, source (hex vs GitHub), and how it integrates with `mix test` are left as open decisions. Two reviewers flagged this; one reviewer correctly noted this is partially acknowledged in the plan's "Open Technical Decisions" section but the plan should at least specify the package source.

## 4. Corrected Findings

| Reviewer Finding | Correction |
|---|---|
| **Gemini: "No explicit data types for event/command fields"** | Downgraded to non-blocking. Elixir/Commanded commands and events are structs with no enforced schema types at the struct level; the Ecto projection schemas will define types. Specifying `String.t()` vs `binary_id` for every field in the plan is unnecessary detail. |
| **Gemini: "Missing error handling strategy"** | Downgraded to non-blocking. The plan specifies aggregate validation rules and valid transitions. Global error handling patterns are project-level concerns, not iteration-plan concerns. |
| **Claude: "Feature files should be shown or referenced with scenario names"** | Partially accepted. The plan references feature file paths and describes scenarios in the goals section. The feature files already exist in the repo. This is non-blocking but listing scenario names in the plan would help. |
| **Codex: "No rollback/migration strategy"** | Rejected as not blocking. This is a greenfield iteration adding new tables and event store setup. Standard Ecto migrations with `mix ecto.rollback` suffice. |
| **Claude: "Recipient count update trigger unclear"** | Accepted and merged into the process manager gap. The `messages.recipient_count` field is updated by `DeliveryCreated` events, but the mechanism that creates those events is the same unspecified process manager. |
| **Gemini: "Status mapping for member receipt is ambiguous"** | Partially accepted. The plan says the receipt maps to `sent`, `delivered`, `delivery problem`, or `opened`, but doesn't specify which domain statuses map to `delivery problem`. This is a minor product decision that should be explicit. Upgraded to blocking since it's a product/business mapping. |

## 5. Blocking Gaps

1. **Aggregate identity and stream strategy.** The plan must specify: (a) how aggregate IDs are generated (UUID v4 at command dispatch time? caller-provided?), (b) the stream naming convention (e.g., `Club-{id}`, `Person-{id}`, `Messaging-{id}`), and (c) what constitutes the Messaging aggregate's identity — is it per-message, per-club, or something else? Without this, the engineer must make a foundational architectural decision.

2. **Commanded application and router configuration.** The plan must specify: (a) whether there is a single `Memba.App` Commanded application or domain-separated applications, (b) how the router dispatches commands to aggregates, and (c) the event store adapter configuration approach (in-memory for test? EventStore for dev?). The plan currently says "Add the Commanded application" but doesn't define its structure.

3. **Delivery creation mechanism.** The plan must specify what component reacts to `MessageSent` to produce `DeliveryCreated` events. Options include: (a) a Commanded process manager, (b) a Commanded event handler that dispatches `CreateDelivery` commands back to the Messaging aggregate, or (c) the `SendMessage` command handler itself emitting both `MessageSent` and all `DeliveryCreated` events in one batch. Each has different consistency and testability characteristics. This is a material technical design decision.

4. **Member receipt status mapping.** The plan must specify which domain delivery statuses (`sent`, `delivered`, `delayed`, `bounced`, `spam_complaint`, `opened`) map to which member-facing receipt statuses (`sent`, `delivered`, `delivery problem`, `opened`). Specifically: does `delayed` map to `sent` or `delivery problem`? Does `spam_complaint` map to `delivery problem`? This is a product decision.

5. **Cucumber package source and integration.** The plan must specify whether `huddlz-hq/cucumber` is a Hex package or a GitHub dependency, and how feature files in `acceptance-tests/features/` are discovered and executed within `mix test`. The "stop and report if incompatible" instruction is good, but the engineer needs to know where to find the package to begin.

## 6. Non-blocking Improvements

1. **List scenario names from the feature files** in the plan for traceability, even though the files exist in the repo.
2. **Specify the Ecto repo and database** for the event store vs. read-model projections (same database? separate schemas?).
3. **Clarify whether `Person` email uniqueness** is enforced at the aggregate level, projection level, or both.
4. **Add a dependency list** with approximate version constraints for `commanded`, `commanded_eventstore_adapter`, `eventstore`, and the cucumber package.
5. **Clarify the `deliveries.sent_at` semantics** — is this the time the fake provider accepted the message, or the time the `DeliveryCreated` event was produced?
6. **Consider whether `opened` should really be terminal.** A message can be opened multiple times. The plan says "opened rejects further status changes" which prevents tracking re-opens. This may be intentional for this iteration but should be explicitly noted as a simplification.

## 7. Smallest Viable Iteration

The current scope is already a reasonable first slice. However, if it proves too large during implementation, the smallest viable sub-slice would be:

**Sub-slice A:** Club creation, person creation, member addition, and message sending (aggregates + events + projections) — without delivery status tracking. This would exercise the full Commanded stack, Ecto projections, and Cucumber integration, and would validate the member-message scenarios (excluding deliverability status).

**Sub-slice B (current plan):** The full plan as written, including delivery status tracking, is the intended smallest useful slice and is appropriate if the blocking gaps are resolved.

## 8. Validation Plan

- All shared Cucumber scenarios in `acceptance-tests/features/member_message_deliverability.feature` and `acceptance-tests/features/operator_email_deliverability.feature` pass against the Elixir domain model.
- ExUnit tests cover aggregate validation rules, invalid state transitions, duplicate idempotency, projector behavior, and fake provider interactions.
- `devenv shell mix precommit` passes cleanly.
- No live provider or UI is required.

## 9. Corrected Iteration Plan Draft (Patch-Style Edits)

The following edits should be applied to the existing plan at `docs/iterations/001-member-message-deliverability/plan.md`:

---

### Edit 1: Add new section after "## Implementation Steps" preamble, before step 1

Insert:

```markdown
## Technical Design Decisions

### Aggregate Identity and Streams

- All aggregate IDs are UUID v4, generated by the caller (test or application service) at command dispatch time.
- Stream names follow Commanded defaults: `{AggregateModule}-{uuid}` (e.g., `Memba.Messaging.Aggregates.Club-<uuid>`).
- The **Club** aggregate is identified by `club_id`. One stream per club.
- The **Person** aggregate is identified by `person_id`. One stream per person.
- The **Messaging** aggregate is identified by `message_id`. One stream per message. The `SendMessage` command creates the stream; `RecordDeliveryStatus` targets the same stream via the `message_id` embedded in the `delivery_id` mapping (see Delivery Creation below).

### Commanded Application and Router

- A single Commanded application module: `Memba.Messaging.App`.
- A single router module: `Memba.Messaging.Router`.
- The router dispatches `CreateClub` → `Club` aggregate, `CreatePerson` → `Person` aggregate, `AddMember` → `Club` aggregate, `SendMessage` → `Messaging` aggregate, `RecordDeliveryStatus` → `Messaging` aggregate.
- Event store adapter: `Commanded.EventStore.Adapters.EventStore` for dev and test. The EventStore database is configured in `config/dev.exs` and `config/test.exs`. In-memory adapter is NOT used; the EventStore adapter provides closer parity with production.

### Delivery Creation Mechanism

- The `SendMessage` command handler on the Messaging aggregate emits `MessageSent` followed by one `DeliveryCreated` event per recipient, all in a single batch of events from the `execute/2` callback. This keeps delivery creation synchronous and transactional within the aggregate, avoiding the need for a process manager in this iteration.
- Each `DeliveryCreated` event contains a generated `delivery_id` (UUID v4), the `message_id`, `recipient_person_id`, and `recipient_email`.
- The `RecordDeliveryStatus` command includes `delivery_id`. The Messaging aggregate's state tracks deliveries by `delivery_id`, allowing it to validate status transitions.
- The fake email provider port is called by an event handler (not the aggregate) that reacts to `DeliveryCreated` events. In this iteration the fake always succeeds, but the handler will dispatch a `RecordDeliveryStatus` command with status `:sent` on success. This means the aggregate will receive `DeliveryCreated` (from SendMessage) and then `DeliveryStatusRecorded` (from the event handler's command) as separate transactions, which is the intended design for real provider integration.

**Correction:** Given this design, the `SendMessage` command handler needs to receive the list of recipient person IDs and their emails. This means the application service layer (or the test) must resolve club membership before dispatching `SendMessage`. The command struct is:

```
SendMessage{message_id, club_id, sender_person_id, subject, body, recipients: [%{person_id, email}]}
```

### Member Receipt Status Mapping

The member-facing receipt query maps domain delivery statuses to simplified display statuses:

| Domain Status | Receipt Display Status |
|---|---|
| `sent` | `sent` |
| `delivered` | `delivered` |
| `delayed` | `sent` |
| `bounced` | `delivery problem` |
| `spam_complaint` | `delivery problem` |
| `opened` | `opened` |

### Cucumber Package

- Package: `huddlz_hq/cucumber` from GitHub (`{:cucumber, github: "huddlz-hq/cucumber"}`).
- Feature files in `acceptance-tests/features/` are referenced by the test configuration. Step definitions live in `test/support/cucumber/` or a similar path chosen during implementation.
- Cucumber tests run as part of `mix test`. If the package is incompatible with the current Elixir/OTP version or Commanded test setup, stop and report rather than switching approaches.
```

---

### Edit 2: In step 3 (Commanded, EventStore dependencies), replace the current text with:

```markdown
3. Add Commanded and EventStore dependencies: `commanded`, `commanded_eventstore_adapter`, `eventstore`, `commanded_ecto_projections`. Configure the `Memba.Messaging.App` Commanded application module and `Memba.Messaging.Router`. Configure the EventStore database in `config/dev.exs` and `config/test.exs`. Run `mix event_store.create` and `mix event_store.init` as part of setup.
```

---

### Edit 3: In step 6 (Messaging aggregate), update the `SendMessage` command definition:

Replace:
```
Command: `SendMessage{message_id, club_id, sender_person_id, subject, body}`.
```
With:
```
Command: `SendMessage{message_id, club_id, sender_person_id, subject, body, recipients}` where `recipients` is a list of `%{person_id: uuid, email: string}`. The caller (application service or test) resolves membership before dispatch.
```

And add after the `DeliveryCreated` event description:
```
The `SendMessage` handler emits `MessageSent` followed by one `DeliveryCreated` per recipient in a single event batch. No process manager is needed for delivery creation in this iteration.
```

---

### Edit 4: In the "Open Technical Decisions" section, remove the bullet about folder structure for Cucumber step definitions (this is genuinely open and fine) but update the package versions bullet:

Replace:
```
- Exact package versions for `commanded_eventstore_adapter`, `eventstore`, and `cucumber` should be chosen during implementation by selecting versions compatible with the existing Elixir, Phoenix, and Commanded versions.
```
With:
```
- Exact package versions for `commanded`, `commanded_eventstore_adapter`, `eventstore`, and `commanded_ecto_projections` should be chosen during implementation by selecting versions compatible with the existing Elixir/OTP and Phoenix versions. The cucumber package is `{:cucumber, github: "huddlz-hq/cucumber"}` pinned to the latest commit on `main` at implementation time.
```

---

### Edit 5: In step 6, after the delivery status transition rules, add:

```markdown
- Note: `opened` is treated as terminal in this iteration (no re-open tracking). This is an intentional simplification.
```

---

These edits resolve all five blocking gaps. The plan should be re-reviewed after these edits are applied.

---

{"context_updates":{"plan_ready":false}}