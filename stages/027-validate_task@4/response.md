### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - Live working tree has no ordinary diff; only untracked `.fabro/tmp/`.
  - Recent implement checkpoint `1a9e5ad fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - task `004` from `- [ ]` to `- [x]`.
  - The prior todo state from `1a9e5ad^` shows task `004` was the first unchecked task.

- Implementation artifacts found.
  - `1a9e5ad` added `docs/iterations/020-migrate-production-email-to-postmark/task-004-postmark-inbound-routing-decision.md`.
  - The artifact records the routing decision:
    - add future inbound route `POST /webhooks/postmark/inbound`;
    - keep existing delivery-status route `POST /webhooks/postmark`;
    - implement inbound handling with a dedicated `MembaWeb.PostmarkInboundWebhookController`;
    - avoid payload-shape dispatch in the existing delivery-status controller.
  - It also carries forward useful implementation details for later tasks: `MessageID` for idempotency, inbound payload fields, attachment metadata, and `clubs.memba.io` MX setup.

- Tests run/results found.
  - This was a documentation/technical-decision task with no executable code/config/app-behaviour changes.
  - I reran `git diff --check 1a9e5ad^ 1a9e5ad`; it passed.
  - No app test or `dev check` run is required for this docs-only decision slice; final `dev check` remains task `016`.

- ADR/plan conformance notes.
  - Work stayed within task `004` and preserves later implementation scope for tasks `005` through `016`.
  - ADR 0016 is respected: provider-specific webhook parsing remains at the web/controller boundary while shared domain APIs stay provider-neutral; Resend remains available.
  - ADR 0014/0017 operational concerns are preserved by documenting production URL/DNS implications for later runbook work.
  - ADR 0018 is unaffected; no devenv/process orchestration changes were made.
  - No acceptance feature files were edited.
  - The task is small and independently checkpointed with a clear evidence artifact.

{"context_updates":{"task_valid":true,"task_retry_available":false}}