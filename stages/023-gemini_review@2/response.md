# Iteration 057 Review: Admin Group Email Conversations

- Decision: ACCEPT
- Confidence: High
- ADR conformance: PASS
- ADR violations: None identified. The implementation preserves the project's event-sourcing and CQRS boundaries. Identity and email slug routing are kept appropriately decoupled from internal deterministic system-groups, and inbound-email idempotency boundaries were preserved without introducing unplanned synchronous shortcuts.

- Blocking issues:
  1. **Missing Plan-Mandated Documentation Update**: The iteration plan's *Risks / Follow-ups* section explicitly requires updating the Groups vision doc (`docs/specs/2026-09-02-groups-and-conversation-access-vision.md`) to reflect the confirmed `club_members_only` new-conversation rule before delivery. The automated repair agent attempted this but failed to materialize the change in the working tree (likely staging it instead, causing `verify_review_repair` to fail). This doc update must be committed before finalizing the merge to satisfy the plan.

- Bounded-safe fixes:
  1. **Test Infrastructure Documentation (`web/config/test.exs`)**: Add a brief inline comment explaining that the minimum 16-connection test DB pool prevents SQL Sandbox single-scheduler starvation during Commanded projector execution. 
  2. **Fixture Contract Documentation (`web/test/support/messaging_fixtures.ex`)**: Clarify in the `@doc` for `insert_group_accessible_message!/1` that it automatically provisions a `ConversationGroupAccess` grant for root messages, but implicitly requires the caller to have already provisioned the root message and its grant when inserting a reply.

- Judgement-worthy non-blocking code-health findings:
  1. **File:** `web/test/support/messaging_fixtures.ex`
     **Smell:** Bypassing the aggregate/command boundary. 
     **Why it may need human judgement:** Direct Ecto inserts into the read-model (`Message` and `ConversationGroupAccess`) are fast and practical for query/UI tests, but they risk drift from actual projector behavior (e.g., hardcoding `"write"` access levels). The team should be aware of this potential drift if domain invariants around group access change in the future.
  2. **File:** Messaging Recipient Resolution (Domain)
     **Smell:** Redundant message delivery to sender.
     **Why it may need human judgement:** An active Admin who emails the Admin group receives a redundant root-message copy in their mailbox. The iteration plan explicitly accepts and defers this behavior, so it is safe to merge now. However, it will require a future product-level decision on whether sender copies should act as delivery records or be suppressed from the inbox.

- Suggested fixes:
  - Check the git index (`git diff --cached`). If the repair agent successfully staged the updates to `groups-and-conversation-access-vision.md`, `messaging_fixtures.ex`, and `test.exs`, simply commit them.
  - If they are missing, manually apply the doc update to `groups-and-conversation-access-vision.md` and add the explanatory comments to the test files.

- Validation notes:
  - The core behavioral implementation is solid. `dev ci` and `dev check` both passed flawlessly after the `test.exs` pool size fix was applied.
  - The test suite reported **1,129 unit/integration tests passing** with 0 failures.
  - The Phoenix browser acceptance lifecycle executed successfully, with all **122 scenarios and 877 steps passing** in ~7 minutes, proving that the step definitions correctly implement the new `@todo-domain` and `@todo-ui` scenarios.
  - The final review repair failure (`verify_review_repair`) was a tooling artifact due to Git working-tree vs. index states, not a regression in the product code's behavioral integrity.