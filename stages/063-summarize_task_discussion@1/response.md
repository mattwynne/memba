Matt’s guidance is to “repair as planned.” The approved product rule remains unchanged: an already-open club Conversations list must show a newly sent conversation without reload or navigation.

The selected work remains task 005:

> Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.

The validator found that the current candidate is incomplete in three concrete areas:

- Dashboard interests omit conversation-only people, such as senders, latest repliers, or participants who are not also present in member or candidate collections. Their exact Person interests must be registered and tested.
- Partially scoped notifications can fail to trigger a necessary conservative refresh:
  - Role definition or permission changes with a role ID but no club ID.
  - `MessageSent` notifications with conversation/message identity but no club ID, including a new root entering the Conversations list.
  - Partial GroupMembership notifications lacking an adequate fallback or the affected Person identity.
- Focused open-dashboard tests are missing for both new root-conversation entry and reply-derived conversation updates.

No new business or architectural constraint was raised, and no question remains for Matt at this stage. Existing iteration boundaries still apply: keep the API provisional, do not expand into conversation-detail migration or package extraction, and do not mark task 005 complete until the repaired candidate is independently validated.

The safe next step is a separate explicit decision to resume from the saved checkpoint, followed by a narrowly scoped revision implementing those interest and fallback repairs, adding the missing focused tests, and returning the result for fresh validation. This clarification does not approve the current candidate, authorize publication, or waive any plan, security, or validation requirement.