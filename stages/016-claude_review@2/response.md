# Iteration Review Report

**Iteration:** 046 — conversation page alignment  
**Reviewed range:** `2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation operates entirely in the presentation layer (LiveView, HEEx templates, CSS) and correctly delegates to existing Messaging context capabilities. No new commands, events, aggregates, projections, or event streams were introduced. The follow/unfollow behavior uses existing `Messaging.follow_conversation/2` and `Messaging.unfollow_conversation/2` functions without bypassing CQRS/event-sourcing infrastructure. Timestamp display uses existing read-model data (`@entry.message.inserted_at`) from the messaging projection without modifying domain behavior or projection shape.

---

## ADR violations

None.

---

## Blocking issues

None.

The implementation is plan-conforming, dev check passed twice (before and after repair attempt), and all requested behaviors are covered by automated tests.

---

## Bounded-safe fixes

None required.

**Note on timestamp helper:** The implementation already uses the optimal `Calendar.strftime/2` approach. The function is correctly named `format_message_time/1` (more specific than generic `format_timestamp/1`), is appropriately private (`defp`), and uses the single-call format string:

```elixir
defp format_message_time(%DateTime{} = inserted_at) do
  Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
end
```

The repair verification failure occurred because no changes were needed—the code was already in the desired state. This is a workflow artifact, not a code quality issue.

---

## Judgement-worthy non-blocking code-health findings

### 1. Timezone display strategy remains implicit

**Files:**  
`web/lib/memba_web/controllers/page_html.ex` (format_message_time/1)  
Messaging projection timestamps (UTC `DateTime`)

**Smell:**  
The UI displays timestamps in UTC without labeling them as UTC or converting to user/club timezone. Users in different timezones may see confusing times.

**Why it may need human judgement:**  
The implementation correctly formats the `DateTime` it receives, but the broader timezone UX strategy needs a product decision:
- Display UTC as-is (current approach)
- Add "UTC" label to timestamps
- Convert to club timezone
- Convert to viewer's local timezone
- Use relative timestamps ("2 hours ago")

Not blocking because the plan explicitly scoped this as timestamp formatting only, but worth deciding before timestamp UI spreads to other screens.

---

### 2. Design-system CSS manually duplicated into production

**Files:**  
`web/assets/css/app.css` (`.follow-toggle`, `.detail-head`)  
`design-system/` reference CSS

**Smell:**  
The plan directed porting CSS from `design-system/` into `app.css` verbatim, creating manual duplication. If design-system styles evolve, they require manual sync.

**Why it may need human judgement:**  
This may be intentional (design-system as read-only reference during MVP), but as more styles are ported, drift risk increases. Consider:
- Documented sync convention/checklist
- Automated drift detection (diff-check between design-system and app.css)
- Shared source-of-truth strategy (import at build time)

Not blocking because the implementation followed the plan's explicit instruction.

---

### 3. Specific timestamp format helper has generic potential

**File:**  
`web/lib/memba_web/controllers/page_html.ex` (format_message_time/1)

**Smell:**  
The helper encodes one specific format (`"3 Jun, 7:02am"`) for conversation/message timestamps. If other contexts need different formats (relative time, full datetime, ISO), multiple similar helpers may emerge.

**Why it may need human judgement:**  
Current naming (`format_message_time/1`) is appropriately specific. If timestamp formatting recurs across screens with different formats, consider:
- A unified helper with format atoms (`:short`, `:full`, `:relative`)
- Per-context helpers with clear naming (current approach, acceptable if formats don't proliferate)

Not blocking because no other timestamp formats are currently needed, and the specific name prevents inappropriate reuse.

---

## Suggested fixes

None. The implementation is already in the optimal state.

The single review issue ("simplify-timestamp-formatting") was a false positive—the code already uses the simplified `Calendar.strftime/2` approach. The repair verification failed correctly because no changes were needed.

---

## Validation notes

- **Dev check:** Passed twice (before review, after repair attempt). Full suite: 85 scenarios, 523 steps, all passing.
- **Feature files:** Unchanged. Domain acceptance criteria remain stable.
- **LiveView tests:** Comprehensive coverage in `web/test/memba_web/live/member_message_live/show_test.exs`:
  - Follow toggle initial state (not following)
  - Follow action via checkbox `phx-change` event
  - Persisted following state via `Messaging.following_conversation?/2`
  - Unfollow action and state reversion
  - Non-member explanation when `!@can_follow_conversation`
  - Composer placement after replies
  - Timestamps present on original message and reply entries
- **No schema/migration changes:** Pure UI iteration.
- **No new domain events/commands:** Uses existing Messaging context capabilities.
- **Visual validation:** Plan calls for `./bin/dev gallery-walk` comparison to `design-system/wireframes/member-conversation.html`. This manual step is not reflected in automated pipeline output but should be confirmed if not already performed.

The implementation is production-ready. No code changes recommended.