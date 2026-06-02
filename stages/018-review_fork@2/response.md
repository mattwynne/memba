# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

### ADR Violations
None.

The implementation correctly adheres to all relevant ADRs:

- **ADR-001 (Use Commanded for CQRS/ES)**: Command/event modules follow Commanded patterns. Deprecated command properly excluded from router dispatch. Event retained for replay compatibility with deserialization warning.
- **ADR-003 (Projection Schema Design)**: `MemberEmailDelivery` projection schema updated with three-status enum validation that enforces the constraint at the database and application layers.
- **ADR-004 (Email Delivery via Postmark)**: Continues to use Postmark as the provider. Explicitly sets `track_opens: false` in `OutboundEmail.new/1`. Webhook controller rejects open events with 400 "unsupported event type".
- **ADR-007 (Acceptance Testing Strategy)**: Acceptance feature files updated to remove opened scenarios while maintaining domain acceptance criteria for delivered/problem status paths.
- **ADR-009 (Remove Email Open Tracking)**: Newly created ADR correctly documents the decision, context, and consequences. Implementation follows all prescribed changes.

### Evidence
- `web/lib/memba/postmark/outbound_email.ex:17`: `track_opens: false` hardcoded in typespec and implementation
- `web/lib/memba/postmark/webhook_controller.ex:47-48`: Open events return 400 with "unsupported event type"
- `web/lib/memba/messaging/router.ex`: `ReportEmailDeliveryOpened` absent from dispatch list
- `web/lib/memba/messaging/projections/member_email_delivery.ex:12-13`: Status enum limited to `[:sending, :delivered, :delivery_problem]` with schema validation
- `web/test/memba/postmark/outbound_email_test.exs:18`: Explicit test assertion `assert email.track_opens == false`
- `docs/adr/009-remove-email-open-tracking.md`: ADR created with proper structure and content

## Blocking Issues
None.

## Bounded-Safe Fixes

1. **Extract duplicated status display helpers**: Both `MemberDeliveriesLive` and `Staff.ClubDeliveriesLive` contain identical implementations of `status_badge_class/1` and `format_status/1`. Extract these to a shared module:
   - Create `web/lib/memba_web/components/delivery_status_helpers.ex`
   - Move both helper functions to the new module
   - Import the module in both LiveViews
   - Add corresponding test coverage

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Deprecated module lifecycle policy**
   - **Files**: `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`, `web/lib/memba/messaging/events/email_delivery_opened.ex`
   - **Smell**: No documented timeline or policy for eventual removal of deprecated event/command modules
   - **Why judgement-worthy**: This is the first deprecated command in the system. Establishing a project-wide policy now (e.g., "event modules retained indefinitely for replay compatibility; command modules removed after N months of zero dispatch") would prevent technical debt accumulation. Not urgent since the deprecated modules are properly isolated, but worth establishing precedent for future deprecations.

2. **File rename without breadcrumb comment**
   - **Files**: `web/lib/memba/postmark/email.ex` (deleted) → `web/lib/memba/postmark/outbound_email.ex` (created)
   - **Smell**: Module rename has no inline comment explaining relationship to old module name
   - **Why judgement-worthy**: While git history is clear, future developers searching for references to `Postmark.Email` won't find breadcrumbs pointing to the new module. Low-risk since the rename is part of this iteration's scope, but adding a brief moduledoc comment like "Replaces deprecated `Postmark.Email` module" would aid discoverability.

3. **Status display logic duplication across contexts**
   - **Files**: `web/lib/memba_web/live/member_deliveries_live.ex:82-89`, `web/lib/memba_web/live/staff/club_deliveries_live.ex:109-116`
   - **Smell**: Beyond the DRY violation flagged above, the identical status display semantics across member/staff contexts suggest tight coupling
   - **Why judgement-worthy**: If member and staff contexts should truly have independent formatting rules (e.g., different labels, colors, or visibility for certain statuses), the current duplication makes that divergence harder to implement cleanly. Conversely, if the contexts are meant to share display logic permanently, the shared module approach (fix #1) is correct. This is a component architecture decision that depends on product requirements.

## Suggested Fixes

### Bounded-Safe Fix: Extract Status Display Helpers

**Create `web/lib/memba_web/components/delivery_status_helpers.ex`:**
```elixir
defmodule MembaWeb.Components.DeliveryStatusHelpers do
  @moduledoc """
  Shared helper functions for formatting email delivery statuses.
  Used by both member and staff delivery views.
  """

  @doc """
  Returns Tailwind CSS classes for status badge styling.
  """
  def status_badge_class(:sending), do: "px-3 py-1 rounded-full text-sm bg-blue-100 text-blue-800"
  def status_badge_class(:delivered), do: "px-3 py-1 rounded-full text-sm bg-green-100 text-green-800"
  def status_badge_class(:delivery_problem), do: "px-3 py-1 rounded-full text-sm bg-red-100 text-red-800"

  @doc """
  Formats delivery status atom as human-readable string.
  """
  def format_status(:sending), do: "Sending"
  def format_status(:delivered), do: "Delivered"
  def format_status(:delivery_problem), do: "Delivery problem"
end
```

**Update `web/lib/memba_web/live/member_deliveries_live.ex`:**
```elixir
defmodule MembaWeb.MemberDeliveriesLive do
  use MembaWeb, :live_view

  alias Memba.Messaging
  import MembaWeb.Components.DeliveryStatusHelpers

  # ... rest of module, remove duplicated helper functions
end
```

**Update `web/lib/memba_web/live/staff/club_deliveries_live.ex`:**
```elixir
defmodule MembaWeb.Staff.ClubDeliveriesLive do
  use MembaWeb, :live_view

  alias Memba.Messaging
  import MembaWeb.Components.DeliveryStatusHelpers

  # ... rest of module, remove duplicated helper functions
end
```

**Add test `web/test/memba_web/components/delivery_status_helpers_test.exs`:**
```elixir
defmodule MembaWeb.Components.DeliveryStatusHelpersTest do
  use ExUnit.Case, async: true
  import MembaWeb.Components.DeliveryStatusHelpers

  describe "status_badge_class/1" do
    test "returns blue styling for sending status" do
      assert status_badge_class(:sending) =~ "bg-blue-100"
      assert status_badge_class(:sending) =~ "text-blue-800"
    end

    test "returns green styling for delivered status" do
      assert status_badge_class(:delivered) =~ "bg-green-100"
      assert status_badge_class(:delivered) =~ "text-green-800"
    end

    test "returns red styling for delivery problem status" do
      assert status_badge_class(:delivery_problem) =~ "bg-red-100"
      assert status_badge_class(:delivery_problem) =~ "text-red-800"
    end
  end

  describe "format_status/1" do
    test "formats status atoms as readable strings" do
      assert format_status(:sending) == "Sending"
      assert format_status(:delivered) == "Delivered"
      assert format_status(:delivery_problem) == "Delivery problem"
    end
  end
end
```

## Validation Notes

### Tests/Checks Confirming Correctness

1. **Dev check passed**: 380 tests, 0 failures, including:
   - Postmark provider tests explicitly verify `track_opens: false`
   - Webhook controller tests verify open events rejected with 400
   - LiveView tests verify "Opened" status absent from member and staff UIs
   - Projection tests validate three-status-only schema constraint
   - Messaging domain tests cover delivered/problem state transitions

2. **Acceptance test updates**: Both `acceptance-tests/features/member-deliverability.feature` and `acceptance-tests/features/staff-deliverability.feature` removed opened scenarios. Remaining scenarios cover sending, delivered, and delivery_problem paths as domain acceptance criteria.

3. **Domain behaviour verification**:
   - `MessageOutbox` aggregate no longer transitions to opened state
   - `MemberEmailDelivery` projection schema enforces `validate_inclusion(:status, [:sending, :delivered, :delivery_problem])`
   - Messaging context functions work exclusively with three-status model

4. **Integration coverage**:
   - `web/test/memba/postmark/outbound_email_test.exs:18` explicitly asserts `email.track_opens == false`
   - `web/test/memba/postmark/webhook_controller_test.exs` verifies open webhook returns 400 unsupported
   - `web/test/memba_web/live/member_deliveries_live_test.exs:36` uses `refute has_element?(view, "span", "Opened")`
   - `web/test/memba_web/live/staff/club_deliveries_live_test.exs:57` similarly refutes opened display

5. **Documentation updated**: `docs/email-delivery.md` explicitly states open tracking is disabled and references ADR-009.

### Manual Verification Performed

- Confirmed ADR-009 created with proper structure, status, context, decision, and consequences sections
- Verified deprecated event includes `__after_deserialize__/1` callback with compile-time warning for historic data compatibility
- Confirmed `Messaging.Router` excludes `ReportEmailDeliveryOpened` from command dispatch list
- Verified `OutboundEmail` typespec hardcodes `track_opens: false`
- Checked webhook controller returns 400 for open events with appropriate error message

### Remaining Risks

- **Historic event compatibility**: Deprecated event/command modules retained for event store replay. No migration/backfill added per plan: "Do not add a data migration unless implementation discovers the app cannot boot or replay without one." Since dev check passed and app boots successfully, this approach is validated.
- **Third-party tracking independence**: Plan correctly notes "Third-party provider dashboards may still report opens independently if a stream was configured outside Memba." Documentation appropriately states Memba does not request or consume open signals, mitigating scope confusion.

---

**Conclusion**: Implementation is thorough, correct, and well-tested. The single bounded-safe fix (DRY violation) is straightforward polish. Judgement-worthy findings are legitimate architecture considerations for future discussion but do not warrant blocking this merge. Ready to accept with or without applying the bounded-safe fix.