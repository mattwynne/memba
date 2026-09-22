Implemented packet `001-db9620b-01` with result `ready_for_review`.

Changes:

- Added accepted [ADR 0025](/workspace/memba/docs/adr/0025-use-first-class-group-memberships-and-member-owned-conversation-subscriptions.md:1).
- Added its accepted entry to the [ADR index](/workspace/memba/docs/adr/README.md:31).
- Wrote the required [worker result artifact](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json:1).
- Left `todo.md` unchecked and unchanged.

ADR 0025 establishes:

- `Memba.Membership.Club`, routed by `club_id`, as the serialized custom-group membership boundary.
- Fresh caller-generated `group_membership_id` values with `CustomGroupMembershipStarted` and `CustomGroupMembershipEnded`.
- Deterministic, append-only legacy relation reconciliation without inventing historical periods.
- Everyone/Admin as derived system-group consequences without first-class group-membership identities.
- `Memba.Messaging.MemberConversationSubscriptions`, routed by `person_id`, as the canonical subscription ledger.
- Server-resolved provenance, durable prepared follow intents, order-independent revocation, and `GroupMembershipSubscriptionRevocationCompleted` receipts.
- Explicit relationships to ADRs 0007, 0011, 0022, and 0024.

Focused validation passed with exit status 0:

- ADR/index `git diff --check`, plus no-index whitespace validation for the new ADR.
- Resolution of every relative Markdown link.
- Required architecture vocabulary and accepted/index uniqueness assertions.
- Verification that application, acceptance, design, plan, and todo paths were unchanged.
- Worker-result JSON parsing and required-field assertions.

`dev check` was not run because this packet is documentation-only and explicitly excludes executable changes. The pre-existing `.fabro/.../__pycache__/` remains untouched.