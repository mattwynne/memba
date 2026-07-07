# Iteration Review Report

**Iteration:** 046 — conversation page alignment  
**Reviewed range:** `2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation stays within the existing presentation/LiveView boundary for this iteration:

- No new commands, events, aggregates, projections, schemas, migrations, or event streams were introduced.
- Follow/unfollow behaviour continues to use the existing `follow_conversation` / `unfollow_conversation` LiveView events and existing Messaging context capabilities.
- Timestamp rendering uses the already-available read-model value, `@entry.message.inserted_at`, without changing projection shape or domain behaviour.
- The changes are UI/CSS/template/test focused and do not replace ADR-mandated CQRS/event-sourced infrastructure with local shortcuts.

The earlier synthesized blocker, `simplify-timestamp-formatting`, appears to be a false positive: the implementation already uses the desired single `Calendar.strftime/2` format string in `format_message_time/1`.

---

## ADR violations

None.

---

## Blocking issues

None.

The implementation appears plan-conforming, avoids obvious out-of-scope work, and the successful `dev ci` run provides the required behavioural feedback loop.

---

## Bounded-safe fixes

None required.

The timestamp formatting helper is already in the low-risk, maintainable form reviewers requested:

```elixir
defp format_message_time(%DateTime{} = inserted_at) do
  Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
end
```

No additional code polish is necessary before merge.

---

## Judgement-worthy non-blocking code-health findings

### 1. Timestamp timezone policy remains implicit

**Files:**

- `web/lib/memba_web/controllers/page_html.ex`
- Messaging message read-model usage via `@entry.message.inserted_at`

**Smell:**

The UI formats the stored `%DateTime{}` directly. The projection timestamps are UTC, so the displayed time is effectively UTC but is not labelled as UTC or converted to a viewer/club-local timezone.

**Why it may need human judgement:**

This is not a defect in this iteration; the plan explicitly scoped timestamp display to formatting existing data. However, before timestamp UI spreads further, the product may need a consistent policy:

- display UTC as-is,
- label timestamps as UTC,
- convert to club timezone,
- convert to viewer timezone,
- or use relative timestamps.

This should not block merge.

---

### 2. Design-system CSS is manually duplicated into production CSS

**Files:**

- `web/assets/css/app.css`
- `design-system/` reference styles / wireframes

**Smell:**

The plan explicitly asked to port `.follow-toggle`, its children, and `.detail-head` from the design-system mirror into `app.css`. That creates manual duplication between the design reference and app implementation.

**Why it may need human judgement:**

This may be intentional while the design system is a reference artifact, but drift risk increases as more styles are ported. Future options could include:

- documenting a copy/sync convention,
- adding a lightweight drift check,
- or establishing a shared source of truth for reusable design-system styles.

This is not blocking because the implementation followed the iteration plan.

---

### 3. Conversation timestamp helper is intentionally specific

**File:**

- `web/lib/memba_web/controllers/page_html.ex`

**Smell:**

`format_message_time/1` encodes one compact timestamp format: `"3 Jun, 7:02am"`. If more timestamp formats appear, helper proliferation or inconsistent display could follow.

**Why it may need human judgement:**

The current name is appropriately specific and preferable to an over-generic helper. No change is needed now. If timestamp display expands across the app, consider a shared presentation policy or named timestamp formats.

---

## Suggested fixes

None.

No behavioural, domain, schema, route, acceptance-feature, or server-side event changes are recommended.

---

## Validation notes

- `dev ci` / dev check passed successfully.
- Acceptance evidence shows `85 scenarios` / `523 steps` passing.
- Acceptance feature files appear unchanged.
- Automated LiveView evidence covers the important behaviours from the plan:
  - follow toggle initial state,
  - follow action through existing event wiring,
  - persisted following state via `Messaging.following_conversation?/2`,
  - unfollow action and state reversion,
  - non-member explanation instead of interactive toggle,
  - composer rendering after replies,
  - timestamps on original and reply entries.
- No migrations, projection changes, domain events, commands, or aggregates were added.
- The plan’s visual validation step, `./bin/dev gallery-walk`, is not shown in the provided review-stage output. Given the stated plan-conformance gate and green automated checks, this does not change the code-review decision, but it should be considered confirmed separately if the release process requires explicit visual sign-off.