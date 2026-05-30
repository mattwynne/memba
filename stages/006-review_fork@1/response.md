# Iteration 003 Review: Messaging Skeleton

## Decision: ACCEPT

The implementation successfully delivers the messaging skeleton capability as specified in the plan. All acceptance criteria are met with comprehensive test coverage and clean event-sourced architecture.

## Confidence: High

The extensive automated coverage (93 passing tests), passing acceptance scenarios, successful dev check, and adherence to ADR 0013 provide high confidence in this implementation.

## ADR Conformance: PASS

The implementation fully conforms to ADR 0013 (Event-sourced messaging core) and supports ADR 0005 (Channel flexibility).

---

## ADR Violations

None.

---

## Blocking Issues

None.

---

## Bounded-Safe Fixes

1. **Make Fake provider startup conditional on test environment**
   - File: `web/lib/memba/application.ex`
   - Issue: Fake provider is started in all environments, including production
   - Fix: Wrap `{Memba.Messaging.Ports.DeliveryProvider.Fake, []}` in `Mix.env() == :test` conditional
   - Reason: Production doesn't need the test double running as a supervised process

2. **Implement query modules**
   - Files: `web/lib/memba/messaging/queries/get_message.ex`, `list_club_messages.ex`, `list_message_recipient_deliveries.ex`
   - Issue: Query modules return placeholder nil/empty lists despite projections existing
   - Fix: Implement actual `Repo.get_by/2` and `Repo.all/1` calls using MessageProjection and RecipientDeliveryProjection
   - Reason: Projections are built and maintained; queries should use them

3. **Remove or complete placeholder LiveView pages**
   - Files: `web/lib/memba_web/live/message_live/index.ex`, `show.ex`, `web/lib/memba_web/router.ex`
   - Issue: LiveView pages wired into router with non-functional placeholder queries
   - Fix: Either (a) remove pages and routes entirely, or (b) wire them to queries from fix #2
   - Reason: Non-functional routes could confuse developers; finish or remove them

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **ProjectionResetHelper complexity**
   - File: `web/lib/memba/projections/projection_reset_helper.ex` (127 lines)
   - Smell: Complex test helper performing direct SQL operations on projection tables and projection_versions table
   - Why it may need judgement: Might be replaceable with existing commanded_ecto_projections utilities or could be simplified. Works correctly but adds maintenance burden. Consider investigating whether `Commanded.Projections.Ecto.reset!/2` or similar built-in tools could replace this custom implementation.

2. **Incomplete delivery status state machine**
   - Files: `web/lib/memba/messaging/send_message_process_manager.ex`, `web/lib/memba/messaging/projections/recipient_delivery_projection.ex`
   - Smell: Process manager calls delivery provider but doesn't emit outcome events; recipient deliveries remain "queued" status forever, even after successful provider call
   - Why it may need judgement: Intentionally deferred per plan (delivery status transitions are iteration 004 scope), but creates confusing intermediate state where messages are sent but database shows "queued" forever. Comments explain this, but future developers might be confused. Consider either: (a) implementing basic RecipientDeliverySent/Failed events now, or (b) deferring provider calls until status tracking is ready. However, option (b) would break current acceptance criteria requiring provider verification.

3. **Membership.App creation as side-effect**
   - Files: `web/lib/memba/membership/app.ex` (new), `web/lib/memba/membership/projections/member_projection.ex` (changed to use Membership.App)
   - Smell: Created Commanded application for Membership bounded context as part of Messaging iteration; not explicitly in plan
   - Why it may need judgement: Good architectural refactoring—each bounded context should have its own Commanded application. Makes structure more consistent and correct. However, represents scope expansion beyond messaging skeleton. Was likely necessary to make GetClubActiveMemberIds query work properly with projection wiring. Could have been separate "Membership cleanup" iteration, but harmless as-is.

4. **Placeholder LiveView pages (duplicate of bounded-safe #3)**
   - Files: `web/lib/memba_web/live/message_live/index.ex`, `show.ex`
   - Smell: Non-functional pages returning empty/nil data
   - Why it may need judgement: Same as bounded-safe fix #3; documenting here as code-health smell in addition to concrete fix

---

## Suggested Fixes

### Fix 1: Conditional Fake Provider Startup

```elixir
# web/lib/memba/application.ex

def start(_type, _args) do
  children =
    [
      # ... existing children up to Messaging.Supervisor ...
      {Memba.Messaging.Supervisor, []}
    ] ++
    test_only_children()

  opts = [strategy: :one_for_one, name: Memba.Supervisor]
  Supervisor.start_link(children, opts)
end

defp test_only_children do
  if Mix.env() == :test do
    [{Memba.Messaging.Ports.DeliveryProvider.Fake, []}]
  else
    []
  end
end
```

### Fix 2: Implement Query Modules

```elixir
# web/lib/memba/messaging/queries/get_message.ex
def execute(message_id) do
  Memba.Repo.get_by(
    Memba.Messaging.Projections.MessageProjection,
    message_id: message_id
  )
end

# web/lib/memba/messaging/queries/list_club_messages.ex
def execute do
  Memba.Repo.all(Memba.Messaging.Projections.MessageProjection)
end

# web/lib/memba/messaging/queries/list_message_recipient_deliveries.ex
import Ecto.Query

def execute(message_id) do
  from(d in Memba.Messaging.Projections.RecipientDeliveryProjection,
    where: d.message_id == ^message_id,
    order_by: [asc: d.queued_at]
  )
  |> Memba.Repo.all()
end
```

### Fix 3: Complete LiveView Pages

After implementing fix #2, update LiveView pages:

```elixir
# web/lib/memba_web/live/message_live/index.ex
defp list_messages do
  Memba.Messaging.Queries.ListClubMessages.execute()
end

# web/lib/memba_web/live/message_live/show.ex
defp get_message(id) do
  Memba.Messaging.Queries.GetMessage.execute(id)
end

defp list_message_recipient_deliveries(id) do
  Memba.Messaging.Queries.ListMessageRecipientDeliveries.execute(id)
end
```

---

## Validation Notes

### Acceptance Criteria Validated

1. ✓ **Sending to club addresses exactly active members**: Verified by `send_message_to_club_test.exs` and cucumber scenario "A member sends a club message"
2. ✓ **One recipient delivery record per recipient**: Verified by recipient_delivery_projection_test.exs and integration tests
3. ✓ **Fake provider called once per recipient**: Verified by integration tests checking `DeliveryProvider.Fake.get_deliveries()` and cucumber assertions
4. ✓ **Cucumber scenario passes**: Confirmed in cucumber-report.json (all steps passing)
5. ✓ **ExUnit coverage complete**: 93 tests passing covering aggregates (message_test.exs), process manager (send_message_process_manager_test.exs), application service (send_message_to_club_test.exs), projections, and fake provider
6. ✓ **Dev check passes**: Confirmed in stage output

### ADR 0013 Conformance Verified

- ✓ Message aggregate with `execute/2` and `apply/2` functions
- ✓ SendMessage command structure
- ✓ MessageSent and RecipientDeliveryQueued events emitted correctly (one delivery event per recipient)
- ✓ SendMessageProcessManager handles RecipientDeliveryQueued and calls provider
- ✓ DeliveryProvider behaviour with channel-neutral `send_message/3` callback
- ✓ Fake implementation for testing
- ✓ Projections for messages and recipient_deliveries tables

### Test Coverage Breakdown

- **Aggregate**: `message_test.exs` (199 lines) - command execution, validation, event emission
- **Process Manager**: `send_message_process_manager_test.exs` (217 lines) - event handling, provider calls, success/failure cases
- **Application Service**: `send_message_to_club_test.exs` (168 lines) - end-to-end integration test
- **Projections**: `message_projection_test.exs`, `recipient_delivery_projection_test.exs`
- **Queries**: `get_club_active_member_ids_test.exs` (115 lines) - recipient resolution
- **Provider**: `delivery_provider_test.exs` (89 lines) - fake provider behavior
- **Acceptance**: `messaging_steps.ex` (254 lines) - cucumber step definitions

### Manual Validation Recommended

1. Navigate to `/messages` route in dev environment to observe placeholder page behavior
2. Verify Fake provider process is not needed in dev/prod (after fix #1)
3. Review test suite to assess whether ProjectionResetHelper could be simplified using commanded_ecto_projections built-ins