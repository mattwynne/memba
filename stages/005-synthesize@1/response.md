# Final Readiness Review

## 1. Decision: NOT READY

## 2. Confidence: High

All three reviewers independently identified material gaps. While there is strong consensus on the domain model and overall direction, several blocking issues prevent an engineer from beginning implementation without first resolving product/business decisions.

## 3. Consensus Findings

- **Recipient scope is undefined.** All three reviewers flagged that the plan does not specify who receives a club message (all members, selected members, roles, etc.). This is a product decision that changes the command shape, application service logic, and acceptance scenarios.
- **Acceptance scenarios are referenced but not shown.** The plan depends on shared Cucumber feature files as the primary specification, but their content is not included in the plan. An engineer cannot validate the domain model against scenarios that don't exist yet or whose content is unknown.
- **Delivery creation responsibility is ambiguous.** The plan says "the application service… creates one delivery per addressed member" but does not specify who the "addressed members" are, whether delivery creation is synchronous or event-driven, or how failures in delivery creation are handled.
- **Status transition model needs tightening.** The valid-transition list is provided but the plan lacks clarity on idempotency (duplicate webhooks), terminal states, and whether `opened` is truly a delivery status or a separate tracking concern.
- **Projection schemas are underspecified.** The plan lists projection names but not their fields, which projectors build them, or which queries they serve.

## 4. Corrected Findings

| Reviewer Finding | Correction |
|---|---|
| **Gemini: "club_id on Person is wrong"** | **Upgraded to blocking.** The plan's Person aggregate includes `club_id`, but a person can belong to multiple clubs. This is a domain model error that must be corrected before implementation. |
| **Gemini: "Missing Cucumber scenario content"** | **Confirmed as blocking.** Scenarios are the specification; without them, the plan is not self-contained. |
| **Claude: "Email sending should be in scope"** | **Rejected.** The plan explicitly defers real email sending to the next iteration and uses a fake provider port. This is a valid scoping choice, not a gap. |
| **Claude: "Event handler / process manager for delivery fan-out"** | **Downgraded to non-blocking.** The plan can specify that the application service creates deliveries synchronously after the MessageSent event is confirmed. A process manager is an implementation optimization, not a required design decision for this iteration's fake-provider scope. |
| **Codex: "Package version resolution is a gap"** | **Rejected as blocking; kept as non-blocking.** The plan correctly notes this as an open technical decision to resolve during implementation. Package version selection is routine engineering work, not a design decision that blocks starting. |
| **Codex: "Cucumber step definition folder structure"** | **Rejected as blocking.** This is a routine implementation decision. |
| **Claude: "No error/failure scenarios"** | **Downgraded.** For this iteration with a fake provider that always succeeds, error scenarios are not blocking. However, the plan should note that error scenarios will be added when real sending is introduced. |
| **Gemini: "membership_id as aggregate identity"** | **Confirmed as valid concern, upgraded to blocking.** A membership is a relationship (person × club × time range), and the plan doesn't clarify how `membership_id` is assigned or whether it's a natural or surrogate key. |

## 5. Blocking Gaps

1. **Recipient scope undefined.** Who receives a club message? All current members? A subset? The sender too? This is a product decision that determines command shape, application service logic, and test scenarios. The plan must specify the recipient resolution rule.

2. **Person aggregate has `club_id` but a person can belong to multiple clubs.** The `RegisterPerson` command includes `club_id`, coupling a person to one club. This contradicts the separate Membership aggregate. The Person aggregate should be club-independent; club association belongs solely in the Membership aggregate.

3. **Acceptance scenario content is missing.** The plan references two `.feature` files as its primary specification but does not include or summarize their scenarios. Either the scenarios must exist before implementation begins, or the plan must contain the scenario outlines so an engineer knows what to build and a reviewer knows what to validate.

4. **Projection schemas are unspecified.** The plan lists eight projections but provides no field lists, no indication of which events feed them, and no query interface. An engineer cannot build projections without knowing their shape. At minimum, the plan needs field lists for each read model.

5. **Membership identity and lifecycle undefined.** How is `membership_id` assigned? Is membership active by default on creation? Can a membership be revoked? The "current club members" resolution used by the message-sending service depends on knowing what "current" means.

## 6. Non-blocking Improvements

1. **Clarify idempotency for delivery status transitions.** Note whether duplicate webhook events (e.g., two `delivered` notifications) should be silently accepted or rejected.
2. **Specify whether `opened` is a delivery status or a separate tracking event.** This affects the aggregate design but can be deferred to the Postmark iteration if the plan explicitly says so.
3. **Add a dependency diagram** showing aggregate → event → projector → read model flow.
4. **Note that error/failure scenarios** (provider rejects, partial fan-out failure) will be added in the Postmark iteration.
5. **Consider whether the Club aggregate needs any commands beyond `CreateClub`.** For this iteration, a single command is likely sufficient, but note it explicitly.
6. **Specify the event store database setup** (separate DB, same DB, test isolation strategy).

## 7. Smallest Viable Iteration

The current scope is already close to a smallest useful slice. The key refinement: narrow to **one message → fan-out to all current club members → fake provider → project member receipt and operator detail views**. Remove any ambiguity about "addressed members" by defining the rule as "all active members of the club at send time, excluding the sender."

This gives a complete vertical slice: command → aggregate → event → application service → delivery fan-out → projections → Cucumber scenarios validating both member and operator views.

## 8. Validation Plan

1. Shared Cucumber scenarios in `acceptance-tests/features/` pass against the Elixir domain model using `huddlz-hq/cucumber` with fake provider ports.
2. ExUnit tests cover: aggregate invariant enforcement, delivery status transition rules (valid and invalid), projector correctness, and fake provider interaction.
3. `devenv shell mix precommit` passes cleanly.
4. Read model projections return correct data for the scenarios: member sees simplified receipt status; operator sees per-recipient delivery detail.

## 9. Corrected Iteration Plan Draft

The following is a patch-style list of required edits to the existing plan. Edits are numbered and reference the plan's existing structure.

---

### EDIT 1: Add recipient scope rule (new section after step 6 or inline in step 6)

**Add to the Message aggregate / application service description:**

> **Recipient resolution rule:** When a member sends a message to their club, the recipients are all active members of that club at send time, excluding the sender. One Delivery aggregate instance is created per recipient. This rule is intentionally simple for this iteration; future iterations may add recipient selection, roles, or opt-out.

---

### EDIT 2: Fix Person aggregate — remove `club_id`

**Replace the Person aggregate definition with:**

> - **Person aggregate** (`person_id`):
>   - Command: `RegisterPerson{person_id, name, email}`.
>   - Event: `PersonRegistered{person_id, name, email}`.
>   - Invariant: a person stream cannot be created twice.

**Rationale:** A person can belong to multiple clubs. Club association is modeled exclusively through the Membership aggregate.

---

### EDIT 3: Clarify Membership identity and "active" definition

**Replace/expand the Membership aggregate definition:**

> - **Membership aggregate** (`membership_id`, a generated UUID):
>   - Command: `AddMember{membership_id, club_id, person_id, joined_at}`.
>   - Event: `MemberAdded{membership_id, club_id, person_id, joined_at}`.
>   - Invariant: a membership stream cannot be created twice. The application service should enforce that no active membership exists for the same (club_id, person_id) pair before dispatching `AddMember`.
>   - **Active membership:** For this iteration, a membership is considered active from creation and has no end/revocation state. Future iterations will add lapsed/revoked states.

---

### EDIT 4: Add acceptance scenario outlines

**Add a new section "## Acceptance Scenario Outlines" before the Validation Plan, or create the actual `.feature` files as a prerequisite.**

> ### Member Message Deliverability Scenarios
>
> 1. **Member sends a message to club members** — Given a club with 3 members, when member A sends a message, then 2 deliveries are created (one per other member), each with status `sent`, and member A sees a receipt showing the message was sent to 2 recipients.
>
> 2. **Non-member cannot send a message** — Given a club with 2 members and a non-member, when the non-member attempts to send a message, then the command is rejected.
>
> 3. **Member sees simplified receipt** — Given a sent message with deliveries in various statuses, when the member views the receipt, then they see an aggregated summary (e.g., "2 delivered, 1 pending") without per-recipient email addresses.
>
> ### Operator Email Deliverability Scenarios
>
> 4. **Operator sees per-recipient delivery detail** — Given a sent message with deliveries in various statuses, when the operator views delivery details, then they see each recipient's email, current status, and status history.
>
> 5. **Delivery status updates** — Given a delivery with status `sent`, when a `delivered` status is recorded, then the delivery status is `delivered`. When a `bounced` status is then recorded, the transition is rejected (delivered → bounced is not valid).
>
> 6. **Invalid status transition is rejected** — Given a delivery with status `bounced`, when any further status update is attempted, then it is rejected (bounced is terminal).

**Note:** These outlines must be translated into Gherkin in the `.feature` files before implementation begins, or during the first implementation step.

---

### EDIT 5: Add projection field specifications

**Replace step 8 with:**

> 8. Build Ecto projections/read models:
>
>    - **Clubs** (`id`, `name`, `created_at`) — from `ClubCreated`.
>    - **People** (`id`, `name`, `email`) — from `PersonRegistered`.
>    - **Memberships** (`id`, `club_id`, `person_id`, `joined_at`, `active`: boolean) — from `MemberAdded`. For this iteration, `active` is always `true`.
>    - **Messages** (`id`, `club_id`, `sender_person_id`, `subject`, `body`, `sent_at`, `recipient_count`: integer) — from `MessageSent`, with `recipient_count` updated as `DeliveryCreated` events are projected.
>    - **Deliveries** (`id`, `message_id`, `recipient_person_id`, `recipient_email`, `status`, `status_reason`, `sent_at`, `last_status_at`) — from `DeliveryCreated` and `DeliveryStatusRecorded`.
>    - **MessageReceipts** (virtual/query, not a separate table) — query joining Messages and Deliveries, grouped by status, to show the sender an aggregated receipt. Fields: `message_id`, `subject`, `sent_at`, `status_summary` (map of status → count).
>    - **OperatorDeliveryDetails** (virtual/query, not a separate table) — query joining Deliveries with People, for a given message. Fields: `delivery_id`, `recipient_name`, `recipient_email`, `status`, `status_reason`, `sent_at`, `last_status_at`.

---

### EDIT 6: Clarify delivery fan-out mechanism

**Add to step 6, after the Message aggregate description:**

> **Delivery fan-out:** The application service handles delivery creation synchronously after successfully dispatching `SendMessage`. It queries the Memberships read model for active members of the club (excluding the sender), then dispatches one `CreateDelivery` command per recipient. The fake provider port is called before dispatching `CreateDelivery` to simulate handing the email to a provider. If the fake provider returns success, the delivery is created with status `:sent`. For this iteration, the fake provider always returns success.

---

### EDIT 7: Mark `opened` as deferred

**In the Delivery aggregate status list, add a note:**

> The `opened` status and the `delivered -> opened` transition are defined in the aggregate for completeness but will not be exercised in this iteration's scenarios. Open tracking requires a tracking pixel, which belongs to the Postmark integration iteration.

---

These edits resolve all five blocking gaps while keeping the plan's existing structure and scope intact.

---

{"context_updates":{"plan_ready":false}}