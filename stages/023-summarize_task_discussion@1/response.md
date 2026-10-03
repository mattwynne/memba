Matt directed a bounded technical repair for task 008A. This clarification is not acceptance, publication approval, or authorization to resume implementation yet.

Selected task:

> 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.

Matt’s agreed guidance:

- Repair the candidate according to the approved plan.
- Before another worker attempt, audit the full producer → invalidation → query-interest mapping, including Role events and conversation-detail interests.
- Remove the previous restriction against altering role mappings.
- Add loader-count tests that demonstrate both relevant refreshes and unrelated non-refreshes.
- Keep task 008A unchecked and unaccepted.
- Do not publish.

The validator found that revision 5 resolved the earlier malformed-event, fallback-vocabulary, and four-family isolation issues, but affected-query isolation remains incomplete:

- Role permission and role assignment/removal events emit `{:role, role_id}`, although those projectors do not change the Role projection.
- `MemberMessageDetailQuery` registers `{:club_members, club_id}` and `{:group_members, group_id}`. Consequently, another member changing in the same club or audience group can reread an unrelated open conversation detail.
- Current tests assert these broad keys, so the passing focused results—34 adapter tests and 8 query tests—do not prove the required isolation.

Concrete repair examples include removing unchanged Role identity invalidations from relationship-event mappings, removing the broad club-member and group-member interests from conversation detail, and proving at the Binding boundary that unrelated notifications leave the loader count unchanged while exact authorization or relationship changes increment it.

No unresolved business or architectural question was identified. Matt explicitly confirmed the existing approved approach and requested its technical completion.

Safe next step: retain the saved checkpoint and prepare a new bounded task-008A repair packet incorporating Matt’s guidance and the validator’s findings. A separate explicit decision must authorize resumption, followed by focused validation and fresh independent review before task 008A can be accepted.