# Iteration Review Report

**Iteration:** 046 — conversation page alignment  
**Reviewed range:** `2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears ADR-conformant from the supplied plan and implementation evidence. The changes stay in the presentation/LiveView layer, use existing `Messaging` context behaviour for follow/unfollow, and do not introduce new commands, events, aggregates, projections, migrations, or local substitutes for CQRS/event-sourced infrastructure.

The timestamp display uses existing read-model data (`@entry.message.inserted_at`) exactly as the plan decided, rather than changing projection shape or domain behaviour.

---

## ADR violations

None found.

---

## Blocking issues

None.

The implementation is plan-conforming, `dev ci`/dev check passed, and the evidence shows automated coverage for the key behaviours requested by the plan.

---

## Bounded-safe fixes

### 1. Simplify `format_timestamp/1`

**File:** `web/lib/memba_web/controllers/page_html.ex`

The current helper appears to manually combine `Calendar.strftime/2`, `dt.day`, manual minute padding, and manual `am`/`pm` calculation. That is correct, but it can be simplified to one standard format string without changing behaviour.

Suggested replacement:

```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

This should preserve the intended output:

- `~U[2024-06-03 07:02:00Z]` → `"3 Jun, 7:02am"`
- `~U[2024-06-03 12:30:00Z]` → `"3 Jun, 12:30pm"`
- `~U[2024-06-03 00:15:00Z]` → `"3 Jun, 12:15am"`

Risk is low because this is presentation-only and the format is already covered by LiveView assertions.

---

## Judgement-worthy non-blocking code-health findings

### 1. Timestamp timezone policy remains implicit

**Files:**  
`web/lib/memba_web/controllers/page_html.ex`  
messaging message read-model usage

**Smell:**  
The UI formats the stored `%DateTime{}` directly. The plan states the projection uses UTC timestamps, so users may see UTC times without a UTC label or viewer-local conversion.

**Why it may need human judgement:**  
This implementation correctly follows the plan, but future timestamp UI may need a product decision:

- display UTC as-is,
- label timestamps as UTC,
- convert to club timezone,
- convert to viewer timezone,
- or use relative timestamps.

Not blocking for this iteration, but worth deciding before timestamp formatting spreads across more screens.

---

### 2. Design-system CSS is manually duplicated into app CSS

**Files:**  
`web/assets/css/app.css`  
`design-system/` reference assets

**Smell:**  
The iteration explicitly asked to port `.follow-toggle`, its children, and `.detail-head` styles from the design-system mirror into production CSS. That creates manual duplication.

**Why it may need human judgement:**  
This may be intentional while the design system remains a reference artifact. As more styles are ported, drift risk increases. The project may eventually want a documented sync convention, a drift check, or a shared source of truth.

Not blocking because the implementation followed the plan.

---

### 3. Generic helper name encodes one specific timestamp format

**File:**  
`web/lib/memba_web/controllers/page_html.ex`

**Smell:**  
`format_timestamp/1` is a broad name, while the output is specifically the compact conversation/message timestamp format: `"3 Jun, 7:02am"`.

**Why it may need human judgement:**  
The plan explicitly requested this helper name, so this is not a defect. If additional timestamp formats appear later, the project may want a clearer naming or formatting strategy, such as `format_message_timestamp/1` or a shared helper with named formats.

---

## Suggested fixes

Apply the bounded-safe timestamp simplification if polishing before merge:

```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

No behavioural, domain, schema, route, acceptance-feature, or server-side event changes are recommended.

---

## Validation notes

- Dev check completed successfully via `dev ci`.
- Acceptance evidence shows `85 scenarios` / `523 steps` passing.
- Feature files appear unchanged, preserving existing domain acceptance criteria.
- Implementation evidence shows LiveView coverage for:
  - follow toggle initial state,
  - follow/unfollow through existing events,
  - persisted following state via `Messaging.following_conversation?/2`,
  - non-member follow explanation,
  - composer rendering after replies,
  - timestamps on original and reply entries.
- No migrations, projection changes, new domain events, or new commands were introduced.
- The plan’s visual validation step, `./bin/dev gallery-walk`, was not included in the supplied command output. If that check was not already performed by the implementation workflow, it should be confirmed separately, but this does not affect the code-review decision given the stated plan-conformance gate and green automated checks.