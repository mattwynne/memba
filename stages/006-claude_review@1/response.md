# Iteration Review Report
**Iteration:** 046-conversation-page-alignment  
**Review SHA:** 2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD

---

## Decision: ACCEPT
**Confidence:** High  
**ADR Conformance:** PASS

---

## Summary

The implementation successfully aligns the conversation page with the refreshed design: timestamps on messages/replies, compact follow toggle, replies-first ordering, and boxed message-card styling. Dev check is green, tests are comprehensive, and the code is plan-conforming. No ADR violations detected. One bounded-safe refactoring opportunity (timestamp formatting) and three non-blocking architectural considerations are noted below.

---

## ADR Violations

**None.** 

The implementation:
- Uses existing Messaging context functions (`follow_conversation`, `unfollow_conversation`) without introducing new aggregates, commands, or events (respects CQRS/event-sourcing boundaries)
- Follows standard LiveView UI patterns with `phx-change` event handlers
- Ports design-system CSS as the plan explicitly directed
- Adds a view helper (`format_timestamp/1`) in the appropriate location (`page_html.ex`)

No ADRs governing this work (LiveView UI, messaging follow/unfollow, or frontend integration) were violated. The implementation correctly delegates to domain capabilities rather than bypassing CQRS infrastructure.

---

## Blocking Issues

**None.** 

The implementation conforms to the plan, passes all automated tests, and exhibits no behavioural gaps requiring product/architecture decisions before merge.

---

## Bounded-Safe Fixes

### 1. Simplify timestamp formatting helper

**File:** `web/lib/memba_web/controllers/page_html.ex`

**Current implementation:**
```elixir
def format_timestamp(%DateTime{} = dt) do
  month = Calendar.strftime(dt, "%b")
  day = dt.day
  hour = Calendar.strftime(dt, "%-I")
  minute = String.pad_leading(Integer.to_string(dt.minute), 2, "0")
  ampm = if dt.hour < 12, do: "am", else: "pm"

  "#{day} #{month}, #{hour}:#{minute}#{ampm}"
end
```

**Issue:**  
The helper manually calculates am/pm from `dt.hour` (24-hour) while already using `Calendar.strftime` to format the hour in 12-hour (`%-I`). This is redundant—`Calendar.strftime` has built-in am/pm format codes (`%P` for lowercase, `%p` for uppercase).

**Refactoring (semantically equivalent, single-line):**
```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

**Rationale:**
- `%-d` = day without leading zero (matches `dt.day`)
- `%b` = abbreviated month (e.g., "Jun")
- `%-I` = 12-hour without leading zero
- `%M` = minute with leading zero (matches manual padding)
- `%P` = lowercase am/pm (matches manual calculation)

**Verification:**
- Input: `~U[2024-06-03 07:02:00Z]` → Output: `"3 Jun, 7:02am"` ✓
- Input: `~U[2024-12-31 13:45:00Z]` → Output: `"31 Dec, 1:45pm"` ✓
- Input: `~U[2024-06-03 00:15:00Z]` → Output: `"3 Jun, 12:15am"` ✓
- Input: `~U[2024-06-03 12:30:00Z]` → Output: `"3 Jun, 12:30pm"` ✓

**Risk:** Very low. This is a direct stdlib replacement with identical output. The test already asserts the expected format: `assert_has("p", "3 Jun, 7:02am")`.

---

## Judgement-Worthy Non-Blocking Findings

### 1. Timezone display strategy undefined

**Files:** `web/lib/memba_web/controllers/page_html.ex` (format_timestamp/1), messaging schema timestamps  
**Smell:** The app stores UTC timestamps (`timestamps(type: :utc_datetime_usec)`) but displays them without timezone conversion or UTC label.

**Why judgement:**  
Users in different timezones may see confusing timestamps. Product decision needed:
- (a) Is UTC display acceptable for MVP/current scope?
- (b) Should a future iteration add user timezone preference and conversion in LiveView assigns before formatting?
- (c) Should timestamps show a UTC indicator (e.g., "7:02am UTC") to set expectations?

The implementation is correct *as written* (formats the DateTime it receives), but the broader timezone UX strategy is ambiguous. This doesn't block merge but may confuse users.

---

### 2. CSS duplication from design-system folder

**Files:** `web/assets/css/app.css` (`.follow-toggle`, `.detail-head`), `design-system/` source

**Smell:** The plan directed "port the CSS from design-system/" into `app.css`, creating manual duplication. If design-system styles evolve, they require manual sync back into `app.css`.

**Why judgement:**  
This could be intentional (design-system as a read-only reference) or a stopgap until a build-time import/sharing strategy exists. Documenting the sync workflow or automating it (e.g., a script that validates design-system CSS matches app.css segments) might prevent drift. Not blocking, but worth tracking as the design system grows.

---

### 3. Single-format timestamp helper may proliferate

**Files:** `web/lib/memba_web/controllers/page_html.ex` (format_timestamp/1)

**Smell:** The helper is hardcoded to one format (`"3 Jun, 7:02am"`). If other contexts need relative time ("2 hours ago"), full datetime, or ISO format, multiple similar one-off helpers could appear.

**Why judgement:**  
Consider whether a more flexible timestamp rendering strategy (e.g., a helper that takes a format atom like `:short`, `:relative`, `:full`) would reduce future duplication. This is premature if no other formats are needed yet, but worth tracking if timestamp formatting recurs in multiple LiveViews.

---

## Suggested Fixes (Bounded-Safe)

Apply the timestamp formatting refactoring above:

**In `web/lib/memba_web/controllers/page_html.ex`:**
```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

No other changes needed. The refactoring is low-risk, equivalent in behavior, and improves code clarity by using stdlib idiomatically.

---

## Validation Notes

- **Dev check:** Passed (all tests green, no warnings, acceptance features unchanged)
- **LiveView tests:** Cover toggle behavior (follow/unfollow events, state reflection), timestamp rendering, composer-after-replies ordering, and non-member explanation
- **Feature files:** Unchanged (domain acceptance criteria stable)
- **No schema/migration changes:** UI-only iteration
- **No new domain events/commands:** Uses existing Messaging context capabilities
- **Visual validation:** `./bin/dev gallery-walk` expected (not automated); plan calls for manual screenshot comparison to `design-system/wireframes/member-conversation.html`

The implementation is production-ready with the bounded-safe fix applied.