# Iteration 005 Implementation Review

## Decision: ACCEPT

## Confidence: Medium

The implementation appears sound and plan-conforming based on passing tests and partial code evidence, but incomplete file excerpts (specifically missing the "Delay" webhook handler visible in tests but not in the controller excerpt) prevent full verification of all implementation details.

## ADR Conformance: PASS

All cited ADRs are followed correctly:

### ADR 002 (Event-sourced architecture)
✅ **PASS** - Commands dispatched via Router, contexts provide public APIs, projectors update Ecto models
- `Clubs.create_club/2`, `People.create_person/2`, `Messaging.send_club_message/2` all dispatch commands and return IDs
- No direct projection mutations observed

### ADR 003 (Commanded consistency options)
✅ **PASS** - Default eventual consistency, explicit `:consistency` option in public APIs, tests opt into `:strong`
- All context functions: `def create_club(attrs, opts \\ [])` with `consistency = Keyword.get(opts, :consistency, :eventual)`
- LiveViews use default eventual consistency
- Tests use `consistency: :strong` where needed: `Clubs.create_club(%{...}, consistency: :strong)`
- Webhook controller uses default eventual consistency per ADR 008

### ADR 006 (Messaging and Postmark integration)
✅ **PASS** (with planned deferrals)
- Migration adds `postmark_message_id` column to `messages` table with index (20250127000005_add_postmark_message_id_to_messages.exs)
- Outbound Postmark sending correctly deferred per plan ("Out of scope: Full email provider integration, outbound Postmark sending")
- Webhook infrastructure ready for future integration

### ADR 007 (PhoenixTest for browser simulation)
✅ **PASS** - `MembaWeb.FeatureCase` provides event-sourced sandbox setup, PhoenixTest imports, and `assert_eventually/2` helper
- Tests use PhoenixTest DSL: `visit/2`, `click_button/2`, `fill_in/3`, `assert_has/2`
- Located in `web/test/memba_web/live/` as specified
- `assert_eventually/2` helper correctly polls with timeout/interval for projection consistency

### ADR 008 (Postmark webhook event mapping)
✅ **PASS** - Webhook accepts Postmark JSON, extracts MessageID/Recipient, queries projections, maps event types, returns appropriate status codes
- `resolve_delivery_record/2` joins `messages` → `addressed_recipients` → `delivery_records` on `postmark_message_id` and email
- Maps: Delivery → delivered, Bounce → bounced, SpamComplaint → spam_complaint, Open → opened (Delay handler verified by passing test but not visible in excerpt)
- Returns 200/404 as specified; 400 via error tuple
- Ignores SubscriptionChange events
- Uses `Messaging.report_delivery_status/3` as public API
- No signature verification (correctly deferred per ADR)

## ADR Violations: None

## Blocking Issues: None

All acceptance criteria met:
- ✅ Browser routes added under browser pipeline
- ✅ LiveViews for clubs (Index/Show) and messages (Show) implemented
- ✅ POST /webhooks/postmark accepts Postmark events (test evidence confirms Delivery, Delay, Bounce, SpamComplaint, Open handling)
- ✅ PhoenixTest-based LiveView tests cover club creation, person creation, membership, messaging, recipient visibility, non-member exclusion, and status updates
- ✅ Controller tests cover webhook event mappings
- ✅ Router tests include new routes
- ✅ Shared feature files unchanged
- ✅ dev check passes (108 tests, 0 failures)

## Bounded-Safe Fixes

1. **Add missing Ecto schema field for `postmark_message_id`**
   - File: `web/lib/memba/messaging/projections/message.ex`
   - The migration added `postmark_message_id` column and the webhook query uses it, but the schema doesn't expose it
   - Fix:
     ```elixir
     schema "messages" do
       field :club_id, :binary_id
       field :subject, :string
       field :body, :string
       field :sent_at, :utc_datetime
       field :postmark_message_id, :string  # Add this field
     
       timestamps(type: :utc_datetime)
     end
     ```
   - Risk: None - column exists, field currently unused, defaults to nil when not set
   - Benefit: Schema matches database, enables future struct-based access

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Webhook demo requires manual SQL setup** (Files: validation plan, test setup)
   - **Smell**: The validation plan says "POST Postmark-style events and see the member receipt status update" but this requires manually setting `postmark_message_id` via raw SQL first (as `postmark_controller_test.exs` setup does with `Repo.query!("UPDATE messages SET postmark_message_id = 'test-message-id' WHERE id = $1", [message_id])`)
   - **Why judgement-worthy**: Acceptable for salvage scope with deferred outbound sending, but awkward for demos/development. A human might decide to add:
     - Test helper function for easier setup
     - Admin UI to inject test Postmark message IDs
     - Better validation plan documentation
   - Not blocking because acceptance criteria are met and tests prove correct behavior

2. **Incomplete file excerpts in evidence** (Files: evidence collection, postmark_controller.ex)
   - **Smell**: The "Delay" webhook handler is verified by passing tests (`test "handles Delay event"` in postmark_controller_test.exs) but doesn't appear in the controller excerpt shown in evidence
   - **Why judgement-worthy**: Makes code review harder; suggests evidence collection script may need adjustment to capture full files or increase line limits beyond 220
   - Not blocking because dev check passed with all webhook tests green

3. **Eventual consistency in LiveView re-queries** (Files: clubs_live/show.ex, messages_live/show.ex)
   - **Smell**: LiveView event handlers immediately re-query projections after dispatching commands without `:consistency` option:
     ```elixir
     def handle_event("create-person", %{"person" => person_params}, socket) do
       case People.create_person(person_params) do
         {:ok, _person_id} ->
           {:noreply,
            socket
            |> assign(:people, People.list_people())  # May be stale
            |> put_flash(:info, "Person created")}
     ```
   - **Why judgement-worthy**: ADR 003 explicitly allows this ("LiveView event handlers that query projections immediately after dispatching commands may see stale data in production. This is acceptable for most flows"). UI may briefly show stale data before next render/refresh. A human might decide to:
     - Add optimistic UI updates
     - Use strong consistency for critical flows
     - Add UI feedback about async processing
   - Not blocking because it conforms to ADR 003 decision

4. **Basic UI styling** (Files: All LiveView templates)
   - **Smell**: Minimal Tailwind classes, no visual polish (e.g., `clubs_live/index.ex` uses basic `.header`, `.simple_form`, `.table`)
   - **Why judgement-worthy**: Plan explicitly defers "Polished visual design or product UX" but a human might want baseline polish before broader testing
   - Not blocking because out-of-scope per plan

5. **Generic error messages** (Files: All LiveView event handlers)
   - **Smell**: Flash messages lack specifics: `put_flash(socket, :error, "Could not create club")` without error details
   - **Why judgement-worthy**: Acceptable for developer-facing prototype but may need improvement for user-facing features
   - Not blocking because not in acceptance criteria

6. **Deferred operational concerns** (Files: postmark_controller.ex, ADR 008)
   - **Smell**: No webhook signature verification, no retry coordination, no rate limiting
   - **Why judgement-worthy**: ADR 008 and plan explicitly defer these ("The webhook will not validate Postmark's signature in this iteration. Signature verification and retry handling are deferred to a later operational hardening iteration"). Must be addressed before production deployment. A human should ensure these are tracked as follow-up work
   - Not blocking because explicitly deferred per plan

## Suggested Fixes

Apply the single bounded-safe fix:

```elixir
# web/lib/memba/messaging/projections/message.ex
defmodule Memba.Messaging.Projections.Message do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "messages" do
    field :club_id, :binary_id
    field :subject, :string
    field :body, :string
    field :sent_at, :utc_datetime
    field :postmark_message_id, :string  # Add this line

    timestamps(type: :utc_datetime)
  end
end
```

## Validation Notes

**Tests** (108 passed, 0 failures):
- `web/test/memba_web/live/clubs_live/index_test.exs` - club creation via browser
- `web/test/memba_web/live/clubs_live/show_test.exs` - person creation, membership, message sending
- `web/test/memba_web/live/messages_live/show_test.exs` - recipient visibility, non-member exclusion, delivery status updates, eventual consistency handling with `assert_eventually/1`
- `web/test/memba_web/controllers/webhooks/postmark_controller_test.exs` - all event types (Delivery, Delay, Bounce, SpamComplaint, Open, SubscriptionChange, unknown), not_found cases, uses manual SQL to set test Postmark message IDs
- `web/test/memba_web/router_test.exs` - route coverage

**Code quality signals**:
- ✅ Phoenix 1.7+ conventions: component functions, verified routes
- ✅ LiveView patterns: mount/3, handle_event/3, assigns, flash, navigation
- ✅ Ecto conventions: schemas, migrations with indices, query composition
- ✅ Elixir conventions: with pipelines, pattern matching, defp for private functions
- ✅ Test structure: FeatureCase/ConnCase, async: false for event-sourced tests, explicit consistency where needed

**Manual verification recommended**:
1. Confirm "Delay" webhook handler exists in full `postmark_controller.ex` (not visible in 220-line excerpt but proven by passing test)
2. Run manual demo with SQL setup: create club/person/member, send message, manually UPDATE messages.postmark_message_id, POST webhook event, verify status change
3. Verify shared feature files unchanged: `git diff 807da60..HEAD acceptance-tests/features/` should be empty

**Confidence reasoning**:
Medium confidence because evidence excerpts are incomplete (missing Delay handler, possible other truncations) but all tests pass and visible code follows all ADR decisions. The implementation appears correct and complete, but full verification would require seeing complete file contents rather than 220-line excerpts.