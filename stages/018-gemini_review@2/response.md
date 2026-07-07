# Iteration Review Report

**Iteration:** 046 — conversation page alignment  
**Reviewed range:** `2c6de7809569245ce816c79f5ac012d020b8e2ae..HEAD`

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to remain entirely within the presentation/UI layer for this iteration:

- No new commands, events, aggregates, projections, schemas, migrations, or event streams were introduced.
- Follow/unfollow behavior continues to use the existing LiveView events and existing `Messaging` context functions.
- Timestamp rendering uses existing read-model data, `@entry.message.inserted_at`, without modifying projection shape or domain behavior.
- The implementation does not replace ADR-mandated CQRS/event-sourced infrastructure with local shortcuts.

The previously synthesized issue, `simplify-timestamp-formatting`, appears to be a false positive. The supplied evidence shows the helper already uses the intended single `Calendar.strftime/2` call:

```elixir
defp format_message_time(%DateTime{} = inserted_at) do
  Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
end
```

## ADR violations

None.

## Blocking issues

None.

The implementation is plan-conforming based on the supplied evidence, avoids obvious out-of-scope work, and has a successful `dev ci` / dev check run.

## Bounded-safe fixes

None required.

The one candidate bounded-safe fix identified by prior synthesis — simplifying timestamp formatting — is already present in the implementation. No additional low-risk code polish is needed before merge.

## Judgement-worthy non-blocking code-health findings

### 1. Timestamp timezone policy remains implicit

**Files:**

- `web/lib/memba_web/controllers/page_html.ex`
- Messaging message read-model usage via `@entry.message.inserted_at`

**Smell:**

Conversation timestamps are formatted directly from the stored `%DateTime{}`. The plan notes that the projection timestamp is UTC, so the displayed time is effectively UTC but is not labelled as UTC or converted to a user/club-local timezone.

**Why it may need human judgement:**

This is not a defect in this iteration; the plan explicitly scoped the work to displaying the existing timestamp in the design format. However, before timestamp display spreads across more surfaces, the product should decide whether timestamps should be:

- displayed as UTC,
- labelled as UTC,
- converted to club timezone,
- converted to viewer timezone,
- or rendered relatively.

This should not block the merge.

---

### 2. Design-system CSS is manually duplicated into production CSS

**Files:**

- `web/assets/css/app.css`
- `design-system/` reference styles / wireframes

**Smell:**

The iteration plan explicitly required porting `.follow-toggle`, its children, and `.detail-head` styles from the design-system mirror into `app.css`. That creates manual duplication between the design reference and the app implementation.

**Why it may need human judgement:**

This may be intentional while the design-system directory is a reference artifact. As more styles are ported, drift risk increases. Future options could include:

- documenting a copy/sync convention,
- adding a lightweight drift check,
- or establishing a shared source of truth for reusable design-system styles.

This is not blocking because the implementation followed the plan.

---

### 3. Conversation timestamp helper is intentionally specific

**File:**

- `web/lib/memba_web/controllers/page_html.ex`

**Smell:**

`format_message_time/1` encodes one compact display format: `"3 Jun, 7:02am"`. If other timestamp formats appear, similar helpers may proliferate.

**Why it may need human judgement:**

The current name is appropriately specific and preferable to a misleading generic helper. No change is needed now. If timestamp rendering expands across the app, the project may want a shared presentation policy or named timestamp formats.

## Suggested fixes

None.

No behavioral, domain, schema, route, acceptance-feature, or server-side event changes are recommended.

## Validation notes

- `dev ci` / dev check passed successfully.
- Acceptance evidence shows `85 scenarios` / `523 steps` passing.
- Acceptance feature files appear unchanged.
- Automated LiveView evidence covers the important behaviors from the plan:
  - follow toggle initial state,
  - follow action through the existing event wiring,
  - persisted following state via `Messaging.following_conversation?/2`,
  - unfollow action and state reversion,
  - non-member explanation instead of an interactive toggle,
  - composer rendering after replies,
  - timestamps on original and reply entries.
- No migrations, projection changes, domain events, commands, or aggregates were introduced.
- The plan’s visual validation step, `./bin/dev gallery-walk`, is not reflected in the supplied command output. If visual sign-off is required by the release process, confirm that separately; this does not change the code-review decision.