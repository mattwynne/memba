# Audit: projection-only migration compatibility

Date: 2026-09-14

Related incident: [Custom-group creation rejected for legacy clubs](2026-09-14-custom-group-creation-forbidden.md)

Status: Initial repository audit complete; one compatibility proof remains open

## Purpose

The incident showed that a migration can make a read model look correct without adding facts that a later aggregate needs to reconstruct authoritative state. This audit identifies other migrations that changed existing projection data and asks whether each value is:

- a deterministic read-model derivation;
- backed by equivalent event history or explicit replay compatibility; or
- later used by an aggregate or write-side invariant despite being absent from source history.

This is a repository audit, not proof of additional production impact. Only the Admin-role case is confirmed to have caused the incident.

## Findings

| Migration | Projection mutation | Source or deterministic derivation | Write-side consumer or invariant | Classification | Required action |
| --- | --- | --- | --- | --- | --- |
| `20260602001447_add_slug_to_membership_clubs.exs` | Backfills club slugs from names. | Deterministic migration-time slug derivation; older Club events may not carry the projected value. | Current aggregate creation/update validates slugs; existing uses found are principally routing, lookup, and pre-dispatch uniqueness checks. | Watch item, not confirmed drift. A future aggregate decision based on the historical slug could expose a mismatch. | Require a production-history compatibility test before making legacy Club aggregate decisions depend on slug history. |
| `20260602024629_backfill_membership_person_email_addresses.exs` | Creates primary person-email projection rows from `membership_people.email`. | Backed by the email in historic `PersonCreated`; `Person.apply/2` contains legacy compatibility. | Duplicate-email checks and identity lookup use projections; Person commands reconstruct compatible email state. | Compatibility-backed; no same-class defect found. | Keep the replay compatibility test as the proof when email behavior changes. |
| `20260607233402_backfill_membership_administrator_roles.exs` | Inserts Admin role, permission, active assignment, and flattened member permission directly. | No equivalent Club-stream facts were appended for affected legacy clubs. | Club aggregate uses replayed role facts to authorize custom-group creation and protect Admin invariants. | **Confirmed source/projection drift and incident root cause.** | Use the incident's append-only reconciliation and permanent invariant gate. |
| `20260608020000_rename_membership_administrator_role_to_admin.exs` | Renames the built-in role key/name in projections. | Deterministic role ID is unchanged; historic events can retain the earlier key/name. | Admin reconciliation now accepts either exact aggregate definition (`admin` / `Admin` or historic `membership_administrator` / `Membership Administrator`) at the deterministic role ID; Admin authority is derived from deterministic role ID and permission. | Compatibility-backed; production dry-run found one healthy historic definition that this compatibility covers. | Preserve old-key/name aggregate-history tests when expanding role-editing behavior. |
| `20260611041000_normalize_legacy_projection_id_columns.exs` | Prefix-normalizes legacy projection IDs. | Projection-only normalization; source event payload and stream-ID compatibility has not yet been proved by this audit. | Current aggregate commands and replay paths use typed IDs and `Memba.ID.cast/2`. | **Unresolved compatibility risk.** No production mismatch is asserted. | Add a focused replay test using legacy bare-UUID stream/event identities. If it fails, investigate actual production history and design compatibility before changing data. |
| `20260621091504_add_conversation_fields_to_messaging_messages.exs` | Sets legacy `conversation_id` to `message_id`. | Matches compatibility in the Message aggregate/projector: absent historic conversation ID falls back to message ID. | Messaging commands reconstruct the same conversation identity. | Safe deterministic derivation with replay compatibility. | Preserve the fallback test when message/conversation identity evolves. |
| `20260621171600_add_outbound_message_id_to_messaging_email_deliveries.exs` | Backfills outbound delivery IDs. | Matches `Memba.Messaging.OutboundMessageID.for_delivery/2`. | Used for inbound reply lookup, not as an event-sourced aggregate invariant. | Safe deterministic read-model derivation. | No incident action required. |
| `20260713161015_add_verified_at_to_membership_person_email_addresses.exs` | Marks existing projected email addresses verified. | Person replay has a legacy verified-state compatibility value; exact migration timestamps are not treated as source truth. | Email verification commands use compatible aggregate state. | Compatibility shim; no same-class defect found. | Do not make exact legacy verification timestamps authoritative without a source-history design. |
| `20260913221054_add_normalized_group_name_uniqueness.exs` | Backfills normalized group-name keys. | Deterministically matches `GroupName.uniqueness_key/1`; the Club aggregate independently derives its key from `GroupCreated`. | Group-name uniqueness is enforced by the aggregate. | Safe deterministic projection; aggregate authority is already tested. | Retain the test proving aggregate uniqueness when the projection is absent or stale. |

## Confirmed lesson

A projection-only migration is safe only when the projected value is either:

1. derivable from immutable source facts with the same semantics; or
2. paired with explicit aggregate replay compatibility that is tested against the historic event shape.

If a later aggregate will make a decision from the value, directly populating the projection is not enough. The delivery plan must include source-history compatibility, an append-only repair, or a deliberate new invariant boundary before deployment.

## Small follow-up actions

1. Complete the current Admin-history repair and install the blocking source-backed Admin invariant.
2. Add one focused compatibility test for the legacy bare-UUID history implicated by `20260611041000_normalize_legacy_projection_id_columns.exs`.
3. Add a migration-review question to future event-sourced changes: “Will an aggregate later need to reconstruct this backfilled projection value from source history?”
4. Treat a new aggregate dependency on a projection-derived legacy field as a production-history compatibility change requiring representative historic fixtures.

## Evidence paths

- `web/priv/repo/migrations/`
- `web/lib/memba/membership/club.ex`
- `web/lib/memba/membership/person.ex`
- `web/lib/memba/membership/roles.ex`
- `web/lib/memba/messaging/message.ex`
- `web/lib/memba/messaging/outbound_message_id.ex`
- `web/test/memba/membership/create_custom_group_dispatch_test.exs`
- `docs/reference/cqrs.md`
- `docs/reference/event-sourcing.md`
