# Iteration Plan Review: Member Message Deliverability (001)

## Decision: NOT READY

## Confidence: Medium

The plan structure is solid and shows thoughtful design, but critical acceptance criteria are not visible in the provided output, and there's unresolved risk around the core validation approach.

---

## Blocking Gaps

1. **Acceptance criteria not visible**: The plan references two Cucumber feature files as the specification, but they are omitted from the output ("123 lines omitted"). Cannot validate whether acceptance criteria are:
   - Concrete and testable
   - Complete for the stated goal
   - Covering necessary edge cases, permissions, and error states
   - Actually defining clear business decisions

2. **Validation approach has unresolved risk**: The plan mandates using `huddlz-hq/cucumber` but acknowledges it may be incompatible during implementation. Instructions say "stop and report incompatibility" rather than have a fallback. This creates a binary risk: either the chosen tool works or the iteration fails. No alternative validation strategy is defined.

3. **Goal is exploratory, not outcome-focused**: The stated goal is to "prove that Memba can deliver messages" and "using acceptance tests that can execute both as unit tests and as end-to-end tests." This reads more like a technical proof-of-concept than delivering specific user value. What should members and operators be able to DO after this iteration?

---

## Non-blocking Improvements

1. **Aggregate boundaries need more detail**: While commands/events are listed, the plan doesn't explain why Message and Delivery are separate aggregates. What business invariants does this protect? When does a Delivery command fail?

2. **Projection schemas are underspecified**: Step 8 says "build Ecto projections" but doesn't list the specific tables, fields, or queries these projections will support. What read operations must the projections enable?

3. **Membership model gaps acknowledged but not scoped**: The plan calls the membership model "minimal" and defers active/lapsed state, households, privacy, and unsubscribe rules. But will the acceptance criteria reference any of these deferred concepts? If scenarios mention "active members only," that's not actually deferred.

4. **No data setup strategy**: How will tests create the initial clubs, people, and memberships needed to run message scenarios? Through the event store? Through projections? The plan doesn't say.

5. **Cucumber step definition location is vague**: Says "folder structure should be chosen during implementation" but doesn't even suggest a convention (e.g., `test/acceptance/step_definitions/`).

6. **No migration rollback plan**: The plan adds event store tables but doesn't mention how to safely reverse these changes if needed.

---

## Smallest Viable Iteration

Focus on one complete flow with minimal validation complexity:

**Goal**: A club member can send a message to all club members, and the system records each delivery with basic status tracking.

**Scope**:
- Event-sourced aggregates: Club, Person, Membership, Message, Delivery
- Commands: RegisterClub, AddPerson, AddMembership, SendMessage, CreateDelivery, RecordDeliveryStatus
- Events: (corresponding events for each command)
- Status transitions: `sent -> delivered` and `sent -> bounced` only
- One projection: message list with delivery counts (sent/delivered/bounced)
- Fake email provider (always succeeds)
- **Validation**: ExUnit tests only, Cucumber deferred to iteration 002

**Defer**:
- Complex delivery status transitions (delayed, spam, opened)
- Operator deliverability insights projection
- Cucumber integration (validate approach first)
- Invalid transition rejection (keep it simple)

**Success criteria**:
- ExUnit tests demonstrate: creating clubs/people/memberships, sending a message, creating deliveries, recording status
- Projection correctly counts deliveries by status
- All precommit checks pass

This removes the Cucumber integration risk and delivers a working event-sourced foundation that can be enhanced.

---

## Required Plan Edits

1. **Include acceptance criteria in the plan**: Either embed the full Cucumber scenario text or provide a comprehensive alternative definition. Reviewers must be able to validate acceptance criteria completeness.

2. **Rewrite the goal for user value**: Replace "Prove that Memba can..." with something like:
   > "Goal: Enable club members to send messages to other club members through Memba, with the system recording delivery status and preparing for future provider integration. Operators can see which deliveries succeeded or failed."

3. **Define Cucumber fallback strategy**: Either:
   - Remove Cucumber from iteration 001 and start with ExUnit only
   - Identify a specific alternative Cucumber package
   - Define what "stop and report incompatibility" means (fail the iteration? switch to ExUnit?)

4. **Add explicit projection schemas**: For each projection, list:
   - Table name
   - Key fields
   - What queries it must support
   - Example: "Delivery projection: `deliveries` table with `message_id`, `recipient_person_id`, `status`, `sent_at`. Must support: 'all deliveries for a message' and 'delivery counts by status.'"

5. **Clarify membership model for this iteration**: List exactly which membership attributes and rules are IN SCOPE for iteration 001. If scenarios reference "active members," define what that means now.

6. **Add data setup approach**: Add a step: "Define helper functions for test data setup: `given_a_club/1`, `given_a_member/2`, etc. that use the command/event infrastructure to create test scenarios."

---

## Validation Plan

Once the plan is edited:

### Before implementation:
1. Review the full Cucumber scenarios to verify they are complete, testable, and cover necessary cases
2. Verify the fallback validation strategy is clear
3. Confirm projection schemas support the read operations needed by scenarios

### During implementation:
1. Implement aggregates and verify invariants with ExUnit tests
2. Implement projections and verify they rebuild correctly from events
3. Implement application services and verify they coordinate correctly
4. If using Cucumber: implement step definitions and run scenarios
5. Run `devenv shell mix precommit` continuously

### Success criteria:
- [ ] All ExUnit tests pass
- [ ] Cucumber scenarios pass (if included) OR clear documentation of incompatibility
- [ ] Precommit passes with no errors
- [ ] Event store contains events for: club registration, membership, message sending, deliveries
- [ ] Projections reflect current state accurately
- [ ] Can demonstrate: member sends message → deliveries created → status recorded → projection updated

### Stop condition:
All validation checkboxes complete, and the iteration goal is demonstrable through the test suite.

---

## Recommendation

**Revise plan** with required edits, especially:
1. Make acceptance criteria visible and reviewable
2. Remove Cucumber uncertainty or accept ExUnit-only validation for iteration 001
3. Rewrite goal to emphasize user capability, not technical proof

Then re-submit for review before starting implementation.