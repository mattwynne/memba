Implemented packet `task-001-a43a809-inventory-1` with result `ready_for_review`.

Added the evidence-backed [migration matrix](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md), covering:

- All seven in-scope modules, each explicitly marked for migration:
  `MemberDashboardLive`, `MemberGroupLive.New`, `MySettingsLive`, `MemberMessageLive.New`, `MemberMessageLive.Show`, `MemberMessageDeliveryLive.Show`, and `MemberInvitationLive.New`.
- All fourteen club-member routes and their query/result boundaries, current reads and subscriptions, fresh authorization requirements, access-loss behavior, transient-state exclusions, existing proof, and remaining gaps.
- Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, and MemberEmailDelivery projector families.
- Collection-entry/exit and identity interests, old/new scopes, plus conservative fallbacks for:
  - `MessageSent` without audience-group scope
  - role and permission fan-out
  - Person events without club scope
  - historic or malformed delivery notifications without message scope
- The seven deferred stream-backed staff modules: Clubs index/show, Requests index, People index, Deliveries index, and Messages index/show. All other staff, public, auth/onboarding, controller/static, and non-member surfaces are explicitly excluded.
- Existing committed-projector-to-open-dashboard proof, while distinguishing it from the still-`@todo` club-member-entry acceptance example. The missing open delivery-status refresh proof is also recorded.

The required [worker result artifact](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json) was written and validated against the current packet.

Focused validation passed with exit status 0:

- Matrix existence and all seven module checks
- Required field/column checks
- Member and staff route inventory cross-check
- Staff stream implementation cross-check
- Seven LiveView sections and ten projector mapping rows
- Trailing-whitespace and `git diff --check`
- Worker-result JSON parsing and packet identity validation

Final `git status --short` contains only:

```text
?? docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json
?? docs/iterations/067-live-projection-queries/migration-matrix.md
```

`todo.md` remains untouched and unchecked. No executable code changed; as required for this docs-only packet, `dev check` was not run.