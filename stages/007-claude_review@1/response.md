# Implementation Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

### ADR Violations
None.

The implementation correctly adheres to all relevant ADRs:

- **ADR-001 (Use Commanded for CQRS/ES)**: Command/event modules follow Commanded patterns. Router properly excludes deprecated command dispatch. Event deserialization warning is appropriate.
- **ADR-003 (Projection Schema Design)**: `MemberEmailDelivery` projection updated to three-status enum with schema validation enforcing constraint.
- **ADR-004 (Email Delivery via Postmark)**: Still uses Postmark. Explicitly sets `track_opens: false` in `OutboundEmail.new/1`. Webhook controller rejects open events with 400 "unsupported event type".
- **ADR-007 (Acceptance Testing Strategy)**: Acceptance feature files updated to remove opened scenarios while maintaining domain acceptance criteria for delivered/problem statuses.
- **ADR-009 (Remove Email Open Tracking)**: Newly created and correctly implemented throughout the codebase.

### Evidence
- `web/lib/memba/postmark/outbound_email.ex:17`: `track_opens: false` hardcoded
- `web/lib/memba/postmark/webhook_controller.ex`: Open events return `400` with `"unsupported event type"`
- `web/lib/memba/messaging/router.ex`: `ReportEmailDeliveryOpened` dispatch removed
- `web/lib/memba/messaging/projections/member_email_delivery.ex:12-13`: Status enum limited to `[:sending, :delivered, :delivery_problem]`
- `web/test/memba/postmark/outbound_email_test.exs:18`: Explicit test `assert email.track_opens == false`

## Blocking Issues
None.

## Bounded-Safe Fixes

1. **LiveView status helper duplication**: Both `MemberDeliveriesLive` and `Staff.ClubDeliveriesLive` duplicate `status_badge_class/1` and `format_status/1`. Extract to shared module:
   - Create `web/lib/memba_web/components/delivery_status.ex` or similar
   - Move both helpers to shared module
   - Import in both LiveViews
   - Update tests if needed

2. **Deprecated command moduledoc inaccuracy**: `ReportEmailDeliveryOpened` moduledoc claims "will return an error if used" but there's no handler—dispatch would raise `Commanded.Router.UnregisteredCommandError`. Fix moduledoc:
   ```elixir
   @moduledoc """
   DEPRECATED: Open tracking has been removed from Memba.
   This command is retained for backwards compatibility with historic event data
   but is no longer routed. Attempting to dispatch this command will raise an error.
   See ADR 009: Remove Email Open Tracking.
   """
   ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Deprecated module lifecycle policy**
   - **Files**: `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`, `web/lib/memba/messaging/events/email_delivery_opened.ex`
   - **Smell**: No documented timeline or policy for eventual removal of deprecated event/command modules
   - **Why judgement-worthy**: If deprecated modules accumulate without a removal strategy, technical debt grows. May warrant a project-wide policy: e.g., "deprecated event modules retained indefinitely for replay compatibility; deprecated command modules removed after N months if never dispatched." Not urgent since this is the first deprecated command, but worth establishing precedent.

2. **File rename without migration guide**
   - **Files**: `web/lib/memba/postmark/email.ex` (deleted) → `web/lib/memba/postmark/outbound_email.ex` (created); same for test files
   - **Smell**: Simple rename but no inline comment explaining relationship to old module name
   - **Why judgement-worthy**: Future developers searching for `Postmark.Email` references won't find breadcrumbs. Consider adding brief comment in `OutboundEmail` moduledoc: "Replaces deprecated `Postmark.Email` module." Low risk since git history is clear.

3. **Status formatting repetition across member/staff contexts**
   - **Files**: `web/lib/memba_web/live/member_deliveries_live.ex`, `web/lib/memba_web/live/staff/club_deliveries_live.ex`
   - **Smell**: Beyond the DRY issue flagged above, the status display logic is duplicated across member and staff contexts with identical semantics
   - **Why judgement-worthy**: If status formatting rules diverge in future (e.g., staff sees different labels or colors), current duplication makes that harder. Shared component would make divergence explicit. However, premature abstraction may be worse if contexts truly are independent. Judgement call on component extraction strategy.

## Suggested Fixes

### If Bounded-Safe Fixes Applied

**Fix 1: Extract status helpers to shared module**

Create `web/lib/memba_web/components/delivery_status_helpers.ex`:
```elixir
defmodule MembaWeb.Components.DeliveryStatusHelpers do
  @moduledoc """
  Shared helper functions for formatting email delivery statuses.
  """

  @doc """
  Returns Tailwind classes for status badge based on delivery status.
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

Update `web/lib/memba_web/live/member_deliveries_live.ex`:
```elixir
defmodule MembaWeb.MemberDeliveriesLive do
  use MembaWeb, :live_view

  alias Memba.Messaging
  import MembaWeb.Components.DeliveryStatusHelpers

  # ... rest unchanged, remove duplicated helper functions
end
```

Update `web/lib/memba_web/live/staff/club_deliveries_live.ex` similarly.

Add test in `web/test/memba_web/components/delivery_status_helpers_test.exs`:
```elixir
defmodule MembaWeb.Components.DeliveryStatusHelpersTest do
  use ExUnit.Case, async: true
  import MembaWeb.Components.DeliveryStatusHelpers

  describe "status_badge_class/1" do
    test "returns correct classes for each status" do
      assert status_badge_class(:sending) =~ "bg-blue-100"
      assert status_badge_class(:delivered) =~ "bg-green-100"
      assert status_badge_class(:delivery_problem) =~ "bg-red-100"
    end
  end

  describe "format_status/1" do
    test "formats status atoms as strings" do
      assert format_status(:sending) == "Sending"
      assert format_status(:delivered) == "Delivered"
      assert format_status(:delivery_problem) == "Delivery problem"
    end
  end
end
```

**Fix 2: Correct deprecated command moduledoc**

In `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`, replace moduledoc:
```elixir
@moduledoc """
DEPRECATED: Open tracking has been removed from Memba.
This command struct is retained for backwards compatibility with historic event data
but is no longer routed by the Messaging.Router. Attempting to dispatch this command
will raise Commanded.Router.UnregisteredCommandError.
See ADR 009: Remove Email Open Tracking.
"""
```

## Validation Notes

### Tests/Checks Confirming Correctness

1. **Dev check passed**: 380 tests, 0 failures, including:
   - Postmark provider tests verify `track_opens: false` explicitly
   - Webhook controller tests verify open events rejected with 400
   - LiveView tests verify "Opened" status absent from UI
   - Projection tests validate three-status-only schema

2. **Acceptance test updates**: Both `member-deliverability.feature` and `staff-deliverability.feature` removed opened scenarios; remaining scenarios cover delivered and delivery_problem paths.

3. **Domain behaviour**: 
   - `MessageOutbox` aggregate no longer transitions to opened state
   - Projection schema `validate_inclusion` rejects `:opened`
   - Messaging context functions work with three statuses only

4. **Integration coverage**:
   - `web/test/memba/postmark/outbound_email_test.exs` explicitly asserts `email.track_opens == false`
   - `web/test/memba/postmark/webhook_controller_test.exs` verifies open webhook returns 400
   - `web/test/memba_web/live/member_deliveries_live_test.exs:36` uses `refute has_element?(view, "span", "Opened")`
   - `web/test/memba_web/live/staff/club_deliveries_live_test.exs:57` similarly refutes opened display

5. **Documentation updated**: `docs/email-delivery.md` explicitly states open tracking disabled and references ADR-009.

### Manual Checks Performed

- Verified ADR-009 created with correct status, context, decision, and consequences
- Confirmed deprecated event has `__after_deserialize__/1` callback with warning
- Confirmed router excludes `ReportEmailDeliveryOpened` from dispatch list
- Verified `OutboundEmail` typespec hardcodes `track_opens: false`

### Remaining Risks

- **Historic event compatibility**: Deprecated modules retained for event store replay. No migration added. Per plan: "Do not add a data migration/backfill unless implementation discovers the app cannot boot or replay without one." Since dev check passed and app boots, this appears safe.
- **Third-party tracking**: Plan notes "Third-party provider dashboards may still report opens independently if a stream was configured outside Memba." Documentation correctly states Memba does not request or consume open signals, mitigating this risk.

---

**Conclusion**: Clean, thorough implementation. Bounded-safe fixes are optional polish. Judgement-worthy findings are low-priority observations for future policy decisions. Ready to merge.