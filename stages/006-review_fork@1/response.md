# Iteration 003 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: FAIL

---

## ADR violations

1. **ADR 0005 (Messaging Bounded Context) - Provider port integration incomplete**
   - **ADR requirement**: "Delivery provider integration via behaviour-based ports" and "The fake provider port is called exactly once per recipient delivery"
   - **Evidence**: `Memba.Messaging.EventHandlers.DeliveryHandler` exists and implements the provider port integration, but is **not registered in the supervision tree** (web/lib/memba/application.ex shows complete supervision tree without DeliveryHandler)
   - **Impact**: Delivery events are never handled, provider port is never called, acceptance criterion "The fake provider port is called exactly once per recipient delivery" cannot be satisfied
   - **File**: web/lib/memba/application.ex (children list lines 8-19)

2. **ADR 0008 (Projection Versioning) - Version function missing**
   - **ADR requirement**: "Each Ecto projection schema has a `@projection_version` module attribute" and version tracking
   - **Evidence**: `MembaSandbox.SandboxManager.verify_projection_versions/0` calls `module.__projection_version__()` but projection schemas (Message, RecipientDelivery) only define `@projection_version 1` attribute without the corresponding `__projection_version__/0` function
   - **Impact**: SandboxManager init should fail at runtime when verifying versions
   - **Files**: 
     - web/lib/memba/messaging/projections/message.ex
     - web/lib/memba/messaging/projections/recipient_delivery.ex
     - web/lib/memba_sandbox/sandbox_manager.ex (calls `module.__projection_version__()` at line ~35)

---

## Blocking issues

1. **DeliveryHandler supervision missing (ADR 0005 violation)**
   - `Memba.Messaging.EventHandlers.DeliveryHandler` must be added to supervision tree in web/lib/memba/application.ex
   - Without this, no deliveries occur and the fake provider is never invoked
   - Cucumber acceptance criterion "the fake delivery provider should have been called 2 times" cannot pass

2. **Projection version function missing (ADR 0008 violation)**
   - Projection schemas must define `def __projection_version__, do: @projection_version`
   - SandboxManager.verify_projection_versions/0 will crash on undefined function
   - Add to both web/lib/memba/messaging/projections/message.ex and recipient_delivery.ex

3. **Query function referenced but undefined**
   - Tests and Cucumber steps call `MessageQueries.get_message_by_club/1` which does not exist in web/lib/memba/messaging/queries/message_queries.ex (13-line file shown completely)
   - Referenced in:
     - web/test/memba/messaging/services/send_message_service_test.exs line ~21
     - acceptance-tests/features/step_definitions/messaging_steps.exs line ~18
   - Either add the function or the evidence collection is incomplete (but evidence shows complete 13-line module)

4. **FakeDeliveryProvider process message targeting**
   - `Memba.Messaging.Adapters.FakeDeliveryProvider.deliver/2` uses `send(self(), {:fake_delivery, ...})`
   - `self()` resolves to the DeliveryHandler process, not the test process
   - Cucumber step `receive_all_fake_deliveries/1` in messaging_steps.exs cannot receive these messages
   - Fix options:
     a. Configure provider with test PID: `Application.put_env(:memba, :fake_delivery_test_pid, self())` and send to that PID
     b. Move delivery calls into test process scope (bypass event handler for tests)
     c. Use a different verification mechanism (check projection deliveries instead of process messages)

---

## Bounded-safe fixes

None. All identified issues are blocking (ADR violations or acceptance criterion gaps).

---

## Judgement-worthy non-blocking code-health findings

1. **Brittle test synchronization (multiple files)**
   - Tests use `:timer.sleep(100)` to wait for projections
   - Files: web/test/memba/messaging/services/send_message_service_test.exs lines ~16, ~43; messaging_steps.exs line ~16
   - Smell: Race conditions if CI is slow; false confidence if projector fails silently
   - Why judgement: Proper fix requires projection wait helper or test mode synchronous projections; scope beyond iteration
   - Consider: Future iteration adds `Memba.TestHelpers.wait_for_projection/2` with polling

2. **Cucumber step definition naming (acceptance-tests/features/step_definitions/messaging_steps.exs)**
   - Uses `defgiven` for "When" step pattern (line ~8: `defgiven ~r/sends a message/`)
   - Smell: Semantic mismatch between Gherkin keyword and step macro
   - Why judgement: Functional but confusing; cucumber-elixir may alias macros, but `defwhen` would match Gherkin
   - Low risk: Regex pattern match works regardless of macro name

3. **Missing aggregate state validation (web/lib/memba/messaging/aggregates/message.ex)**
   - `execute/2` accepts empty recipients list without validation
   - Smell: Aggregate allows semantically invalid state (message with zero recipients)
   - Why judgement: Business rule clarity - should a club message with no recipients be allowed? Likely needs product decision
   - Current: Empty list passes, creates MessageSent event but no delivery events

4. **Projection schema lacks unique constraints (web/priv/repo/migrations/20250115000002_create_recipient_deliveries.exs)**
   - No unique index on `(message_id, recipient_member_id)`
   - Smell: Event replay or handler restart could create duplicate delivery records
   - Why judgement: Event sourcing best practice is idempotent projections; needs architectural decision on duplicate event handling vs projection deduplication
   - Current: Projector uses `Ecto.Multi.insert` which will fail on duplicate, but error handling unclear

---

## Suggested fixes

### For ADR violations (required before merge):

```elixir
# web/lib/memba/application.ex - add after MessageProjector
children = [
  MembaSandbox.SandboxManager,
  Memba.Repo,
  Memba.EventStore,
  Memba.Membership.App,
  {Memba.Membership.Projectors.MemberProjector, []},
  Memba.Messaging.App,
  {Memba.Messaging.Projectors.MessageProjector, []},
  {Memba.Messaging.EventHandlers.DeliveryHandler, []},  # <-- ADD THIS
  MembaWeb.Telemetry,
  # ...
]
```

```elixir
# web/lib/memba/messaging/projections/message.ex - add after @projection_version
@projection_version 1

def __projection_version__, do: @projection_version  # <-- ADD THIS

@primary_key {:message_id, :string, autogenerate: false}
schema "messages" do
  # ...
```

```elixir
# web/lib/memba/messaging/projections/recipient_delivery.ex - add after @projection_version
@projection_version 1

def __projection_version__, do: @projection_version  # <-- ADD THIS

schema "recipient_deliveries" do
  # ...
```

```elixir
# web/lib/memba/messaging/queries/message_queries.ex - add missing function
def get_message_by_club(club_id) do
  Message
  |> where([m], m.club_id == ^club_id)
  |> order_by([m], desc: m.sent_at)
  |> Repo.all()
end
```

```elixir
# web/lib/memba/messaging/adapters/fake_delivery_provider.ex - fix message target
def deliver(recipient, message_content) do
  test_pid = Application.get_env(:memba, :fake_delivery_test_pid)
  
  if test_pid do
    send(test_pid, {:fake_delivery, recipient, message_content})
  end
  
  :ok
end
```

```elixir
# acceptance-tests/features/step_definitions/messaging_steps.exs - configure test PID
defgiven ~r/^a club "(?<club_name>[^"]+)" exists$/,
         %{club_name: club_name},
         state do
  # ... existing code ...
  
  # Configure fake provider to send to test process
  Application.put_env(:memba, :fake_delivery_test_pid, self())
  
  {:ok, Map.put(state, :clubs, Map.put(state.clubs, club_name, club))}
end
```

### For non-blocking code health (optional, consider in future iteration):

- Add unique index migration: `create unique_index(:recipient_deliveries, [:message_id, :recipient_member_id])`
- Add aggregate validation: `if Enum.empty?(cmd.recipients), do: {:error, :no_recipients}, else: ...`
- Replace `:timer.sleep(100)` with projection wait helper when test utilities iteration lands

---

## Validation notes

**Evidence contradiction with dev check pass:**

The dev check output shows `73 tests, 0 failures`, but the evidence reveals:
1. Missing supervision tree registration that should cause Cucumber provider count assertion to fail
2. Missing query function that should cause compilation failure
3. Missing projection version function that should cause SandboxManager init crash

**Two possible explanations:**
1. Evidence collection incomplete (220-line excerpt limit may hide code in longer files, though affected files appear complete)
2. Implementation differs from collected evidence due to timing or collection script issues

**Decision rationale:**

Given **ADR 0005 explicitly requires** provider port integration and **ADR 0008 explicitly requires** version tracking, and given the evidence shows clear violations of these requirements, I must reject despite the dev check pass. The violations are structural (missing supervision, missing required functions) not behavioural edge cases.

**Required validation after fixes:**
1. Verify DeliveryHandler starts: `iex -S mix` then `Supervisor.which_children(Memba.Supervisor) |> Enum.find(fn {mod, _, _, _} -> mod == Memba.Messaging.EventHandlers.DeliveryHandler end)`
2. Verify projection versions load: check logs for "SandboxManager: Projection versions verified" on startup
3. Re-run: `devenv shell mix precommit` (should still pass after fixes)
4. Manually verify Cucumber scenario: `cd acceptance-tests && bundle exec cucumber features/messaging/send_club_message.feature`