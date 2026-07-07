# Iteration Review Report

**Iteration:** 046 — conversation page alignment  
**Reviewed range:** `2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to stay within the existing architecture:

- No new domain concepts, commands, events, projections, or event streams were introduced for follow/unfollow.
- The follow toggle uses the existing `follow_conversation` / `unfollow_conversation` LiveView events and existing Messaging context behaviour.
- The timestamp work is presentation-only and uses the existing `@entry.message.inserted_at` projection data.
- No evidence of bypassing CQRS/event-sourcing boundaries or replacing ADR-mandated infrastructure with local shortcuts.

---

## ADR violations

None found.

---

## Blocking issues

None.

The implementation is plan-conforming, dev check passed, and the covered behaviours match the requested capability: compact follow toggle, message timestamps, boxed message cards, and composer placement after replies.

---

## Bounded-safe fixes

### 1. Simplify `format_timestamp/1`

**File:** `web/lib/memba_web/controllers/page_html.ex`

The timestamp helper currently appears to manually combine `Calendar.strftime/2`, `dt.day`, manual minute padding, and manual am/pm calculation.

That is correct, but it can be reduced to a single stdlib format string without changing output.

Suggested replacement:

```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

This preserves examples like:

- `~U[2024-06-03 07:02:00Z]` → `"3 Jun, 7:02am"`
- `~U[2024-06-03 12:30:00Z]` → `"3 Jun, 12:30pm"`
- `~U[2024-06-03 00:15:00Z]` → `"3 Jun, 12:15am"`

Risk is low because this is presentation-only and already covered indirectly by LiveView timestamp assertions.

---

## Judgement-worthy non-blocking code-health findings

### 1. Timestamp timezone strategy remains implicit

**Files:**  
`web/lib/memba_web/controllers/page_html.ex`  
conversation/message read-model usage

**Smell:**  
The UI formats the stored `%DateTime{}` directly. Since the projection timestamps are UTC, users may see UTC-local times without any UTC label or user-local conversion.

**Why it may need human judgement:**  
The implementation matches the plan, but the product-level timezone policy is still unclear. Future decisions may be needed around whether timestamps should be:

- shown in UTC,
- labelled as UTC,
- converted to a club timezone,
- converted to a viewer/user timezone,
- or rendered relatively.

This should not block this iteration, but it is worth tracking before timestamp display spreads further.

---

### 2. Design-system CSS is manually duplicated into app CSS

**Files:**  
`web/assets/css/app.css`  
`design-system/` reference files

**Smell:**  
The plan explicitly asked to port `.follow-toggle`, child styles, and `.detail-head` from the design-system mirror into the app stylesheet. That creates manual duplication between the design reference and production CSS.

**Why it may need human judgement:**  
This may be intentional for now, but as more design-system styles are ported, drift becomes likely. The project may eventually want either:

- a documented copy/sync convention,
- automated drift checks,
- or a shared source of truth for design-system styles.

Not blocking because this implementation followed the iteration instructions.

---

### 3. `format_timestamp/1` is generic but currently encodes one conversation-specific format

**File:**  
`web/lib/memba_web/controllers/page_html.ex`

**Smell:**  
The helper name is broad, while the format is specifically the conversation-detail short timestamp format: `"3 Jun, 7:02am"`.

**Why it may need human judgement:**  
If more timestamp formats appear elsewhere, this could lead to several one-off helpers or ambiguous reuse. A future pass may want a more explicit name such as `format_message_timestamp/1`, or a shared presentation helper with named formats.

Not blocking because the plan explicitly requested a `format_timestamp/1` helper in this area.

---

## Suggested fixes

If polishing before merge, apply the bounded-safe timestamp simplification:

```elixir
def format_timestamp(%DateTime{} = dt) do
  Calendar.strftime(dt, "%-d %b, %-I:%M%P")
end
```

No behavioural, schema, routing, acceptance-feature, or domain changes are recommended.

---

## Validation notes

- The workflow’s dev-check stage passed successfully.
- Acceptance suite evidence shows `85 scenarios` / `523 steps` passing.
- The implementation evidence shows LiveView coverage for:
  - follow toggle initial state,
  - follow/unfollow transitions through the existing events,
  - persisted following state via `Messaging.following_conversation?/2`,
  - non-member follow explanation,
  - composer placement after replies,
  - timestamps on original and reply entries.
- No feature-file changes were indicated.
- No migrations or projection changes were needed.
- Manual visual validation via `./bin/dev gallery-walk` was part of the plan; it was not included in the provided command output, so any required screenshot comparison should be confirmed separately if not already done by the implementation workflow.