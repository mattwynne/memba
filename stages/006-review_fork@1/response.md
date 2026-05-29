# Iteration 004 Review Report

**Decision**: ACCEPT

**Confidence**: High

**ADR Conformance**: PASS

---

## ADR Violations

None identified.

**Evidence of conformance**:

1. **ADR 0009 (Email delivery status event sourcing)** - newly created, fully implemented:
   - ✅ Message aggregate owns delivery status transitions (commands: RecordMessageDelivered, RecordMessageDelayed, RecordMessageBounced, RecordMessageSpamComplaint, RecordMessageOpened)
   - ✅ State machine rules enforced in aggregate execute/2 clauses (sent→{delivered,delayed,bounced}, delivered→{opened,spam_complaint}, delayed→{delivered,bounced}, etc.)
   - ✅ Idempotency: duplicate status reports return `[]` (no-op), invalid transitions return `{:error, ...}`
   - ✅ Two projections consuming same event stream: MemberMessageReceipts (simplified) and OperatorMessageDeliverability (full detail with reason text)
   - ✅ Member view maps to three-state model (pending, delivered, failed) per ADR 0006 reference
   - ✅ Operator view preserves delayed_reason, bounced_reason, spam_complaint_reason fields
   - ✅ Repeated opens ignored (first MessageOpened event only)

2. **ADR 0004 (Event sourcing)** - presumed pre-existing, respected:
   - ✅ Commanded infrastructure used properly (dispatch via Memba.App, projectors with Commanded.Projections.Ecto)
   - ✅ Event store isolation (separate schema in config)
   - ✅ Projection versioning table tracked

3. **ADR 0006** - referenced in plan for member receipt mapping:
   - ✅ MemberMessageReceipt schema uses `:pending | :delivered | :failed` status enum
   - ✅ Opened boolean derived from MessageOpened events
   - (ADR 0006 text not in evidence but referenced by ADR 0009 and implemented correctly)

---

## Blocking Issues

None.

---

## Bounded-Safe Fixes

1. **Add projection tables configuration to `web/config/dev.exs`**
   
   **Current state**: `test.exs` contains:
   ```elixir
   config :memba,
     event_sourced_projection_tables: [
       "member_message_receipts",
       "operator_message_deliverability"
     ]
   ```
   
   **Issue**: `dev.exs` does not appear to have this config (not in diff). The sandbox reset tool (`Memba.Dev.Sandbox`) reads projection tables from `Application.get_env(:memba, :event_sourced_projection_tables, [])`. Without this config in dev mode, `bin/dev sandbox-reset` will not truncate the new projection tables, leaving stale data between manual test runs.
   
   **Fix**: Add the same `event_sourced_projection_tables` config to `web/config/dev.exs`:
   ```elixir
   # In web/config/dev.exs, add:
   config :memba,
     event_sourced_projection_tables: [
       "member_message_receipts",
       "operator_message_deliverability"
     ]
   ```
   
   **Impact**: Dev-time tooling only; does not affect test or production behaviour. Ensures consistent sandbox reset behaviour across environments.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Query modules return raw maps instead of schema structs**
   
   **Files**: `web/lib/memba/messaging/queries/*.ex`
   
   **Pattern**: Queries use table name strings and manually construct result maps:
   ```elixir
   from(r in "member_message_receipts",
     where: r.message_id == ^message_id,
     select: %{message_id: r.message_id, status: r.status, ...}
   )
   ```
   
   Instead of:
   ```elixir
   from(r in MemberMessageReceipt, select: r)
   ```
   
   **Smell**: Result shape not enforced by schema; loses compile-time field validation and struct benefits.
   
   **Why human judgement**: This is a deliberate CQRS-style architectural choice to decouple queries from schemas. Queries return DTOs (maps) suitable for API responses or further transformation, rather than entities (structs). Common in event-sourced systems where read models diverge from write models. However, it differs from typical Phoenix patterns where schemas/structs flow through the stack. Decision needed on whether this query pattern should be standardized project-wide or whether certain queries should return structs for type safety.

2. **No validation on provider reason text field lengths**
   
   **Files**: `web/lib/memba/messaging/message.ex`, `web/priv/repo/migrations/20250601000002_create_operator_message_deliverability.exs`
   
   **Pattern**: Events accept arbitrary `reason` strings; database columns are `:text` (unbounded):
   ```elixir
   add :delayed_reason, :text
   add :bounced_reason, :text
   add :spam_complaint_reason, :text
   ```
   
   **Smell**: Email providers could send very long error messages (multi-KB SMTP transcripts, HTML error pages), leading to database bloat. No length validation or truncation.
   
   **Why human judgement**: Provider integration (iteration 005+) will determine actual reason text patterns from Postmark/SendGrid webhooks. Decision needed on acceptable reason length limits (e.g., truncate to 1000 chars vs store full text vs external storage for large reasons). May also need sanitization if reason text is ever displayed in operator UI. Deferring to webhook integration iteration is reasonable, but should be documented as a follow-up concern.

3. **Member and operator projectors structurally similar**
   
   **Files**: `web/lib/memba/messaging/projections/member_message_receipts/projector.ex`, `web/lib/memba/messaging/projections/operator_message_deliverability/projector.ex`
   
   **Pattern**: Both projectors handle the same event types (MessageSent, MessageDelivered, etc.) with similar `handle/3` clauses and update logic.
   
   **Smell**: Duplication of event handling boilerplate across projectors.
   
   **Why human judgement**: ADR 0009 explicitly chooses separate projectors to allow divergent evolution (member view simplifies, operator view adds detail). This is intentional duplication by design, not accidental. However, future maintenance might benefit from shared event handling utilities if the projectors stabilize into consistent patterns. Architectural decision on acceptable duplication vs premature abstraction. Current separation is correct per ADR; flag for revisit if duplication becomes burdensome.

---

## Suggested Fixes

**For bounded-safe fix #1 (projection tables in dev.exs)**:

Add to `web/config/dev.exs`:
```elixir
config :memba,
  event_sourced_projection_tables: [
    "member_message_receipts",
    "operator_message_deliverability"
  ]
```

This ensures `bin/dev sandbox-reset` properly truncates the new projection tables in local development.

---

## Validation Notes

1. **Automated test coverage**: Excellent
   - Message aggregate: status transition happy paths, idempotency, invalid transition errors (web/test/memba/messaging/message_test.exs)
   - Projectors: event handling, status mapping, reason text preservation (web/test/memba/messaging/projections/.../projector_test.exs)
   - End-to-end: Cucumber scenarios pass (acceptance-tests/features/*.feature with step definitions)
   - `dev check` passes: 93 tests, 0 failures

2. **CRUD spike removal**: Confirmed
   - Old `web/lib/memba/messaging/schemas/message.ex` deleted
   - Context (`web/lib/memba/messaging.ex`) now fully event-sourced (command dispatch + queries)
   - No remnant CRUD functions in context

3. **Plan fidelity**: Complete
   - All acceptance criteria met (Cucumber passes, state machine enforced, idempotency works, CRUD spike removed, dev check passes)
   - Out-of-scope items correctly omitted (no Postmark integration, no Phoenix UI, no repeated-open analytics)
   - Implementation plan steps 1-6 all executed

4. **Technical quality**: High
   - Migrations use appropriate constraints, indexes, UUID primary keys
   - Projectors properly supervised in application.ex
   - Sandbox reset tool updated to handle new projection tables (via config)
   - Changeset validation in projectors, proper error handling in aggregate
   - Clear separation of member vs operator concerns per ADR

5. **ADR 0009 creation**: Appropriate and well-structured
   - Documents state machine rules, idempotency approach, projection design
   - References and builds on ADR 0004 (event sourcing) and ADR 0006 (member receipt mapping)
   - Provides clear consequences and future integration guidance

---

**Summary**: Implementation is production-ready with one minor dev-tool config addition recommended. ADR conformance is exemplary, test coverage is comprehensive, and the event-sourced design is clean and maintainable. The judgement-worthy findings are architectural trade-offs (CQRS query pattern, intentional projector separation) that align with the project's event sourcing strategy. No blocking issues prevent merge.