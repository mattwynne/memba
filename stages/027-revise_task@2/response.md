Packet `001-8319b25-03` is complete with result `ready_for_review`.

The accepted architecture in [ADR 0025](/workspace/memba/docs/adr/0025-use-first-class-group-memberships-and-member-owned-conversation-subscriptions.md:215) now closes all four review gaps:

- `PrivateDeliveryAuthorizationCutoverFenceRecorded` fences a restartable legacy-delivery sweep. `LegacyPrivateEmailDeliveryMarkedIneligible` permanently blocks pending, startup-recovered, dispatching, and manually retryable private deliveries that lack creation-time provenance. Exact retries and restarts are idempotent; remove/re-add cannot revive them; provider-accepted deliveries remain untouched.
- Manual follow prepares and activates immediately. Reply auto-follow prepares before sending and activates only after the correlated success. Root auto-follow commits `MessageSent` and its audience grant first, then resolves the exact captured sender authority. Outside-group senders receive `RootConversationSubscriptionSkipped`, while rejected roots leave no prepared follow.
- Historic reconciliation now uses explicit precedence:

  | State | Result |
  | --- | --- |
  | Prepared only or `send_rejected` | Historic grant may be authorized |
  | Effective canonical grant | `superseded_by_canonical_grant` |
  | Explicit unfollow | `suppressed_by_unfollow` |
  | Exact relevant revocation | `suppressed_by_relevant_revocation` |
  | Unrelated revocation | Continue normal evaluation |
  | Unproved source/provenance | `unproved` |

- Every successful intent has a deterministic immutable `subscription_authorization_id`. Same-intent retries are event-free; different intents create distinct grants; subscriptions remain effective while any grant survives. Unfollow closes all prior grants. Membership revocation atomically appends one membership-wide tombstone, ordered conversation-scoped provenance/grant consequences, and one completion receipt last.
- Followed deliveries bind to one exact grant and its captured membership provenance. Another grant, a later follow, or re-addition cannot revive queued work associated with the old grant.

Only ADR 0025 was changed as packet content. The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json:1). `todo.md` remains untouched.

Validation passed with exit status 0:

- ADR whitespace validation
- Relative Markdown-link resolution
- Required-contract text assertions
- Worker scope validation
- Worker-result JSON/schema and packet-identity validation

`dev check` was not run because this packet explicitly prohibits full-suite commands for its documentation-only scope; the workflow’s later deterministic gate owns that run. The unrelated Fabro-generated `__pycache__` remains untouched.