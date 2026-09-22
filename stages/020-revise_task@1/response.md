Packet `001-50c18db-02` is `ready_for_review`.

Revised [ADR 0025](/workspace/memba/docs/adr/0025-use-first-class-group-memberships-and-member-owned-conversation-subscriptions.md) to define:

- Atomic, retry-stable creator membership during `CreateCustomGroup`.
- One-current-membership uniqueness and exact direct/club-departure termination.
- Zero/one/many revocation receipt correlation.
- Durable auto-follow preparation, cancellation, and `MessageSent` intent correlation.
- Exact queued-delivery membership and subscription provenance.
- High-water reconciliation fences, checkpoints, aggregate revalidation, and live-write precedence.

All focused checks passed with exit status 0:

- Whitespace validation.
- Relative Markdown link resolution.
- Required-contract assertions covering every review gap.
- Scope-exclusion verification.
- Worker-result JSON parsing and identity verification.

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json). `todo.md` remains unchecked and untouched. No executable, acceptance, design, plan, or ADR-index files changed. Per the documentation-only packet, `dev check` was not run. The pre-existing untracked workflow `__pycache__` was preserved untouched.