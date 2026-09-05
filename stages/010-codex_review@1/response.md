# Iteration Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

None identified.

The implementation evidence is consistent with the project’s accepted CQRS/event-sourcing boundaries:

- Group email slugs are represented separately from deterministic system-group identity.
- Membership state changes continue through the established command/event path, while slug and group lookups are served through projections.
- Messaging authorization is represented as projected conversation-to-group access rather than being inferred from message recipients at query time.
- Existing provider/message idempotency remains the inbound-email identity boundary.
- The initial `club_members_only` behavior remains a fixed policy boundary rather than introducing an unplanned persisted setting.
- Existing member-facing surfaces remain explicitly scoped to Everyone while the underlying query API becomes group-aware.

No evidence showed an ADR-mandated component being bypassed or replaced with local persistence or synchronous shortcuts in production code.

## Blocking issues

None.

The implementation appears faithful to the planned Admin-group capability, and the successful full check provides coverage for the relevant behavior and regressions. No missing permission case, unsafe migration behavior, or acceptance-level gap is apparent from the supplied evidence.

## Bounded-safe fixes

1. **Clarify the projection fixture’s root/reply contract**
   - **File:** `web/test/support/messaging_fixtures.ex`
   - `insert_group_accessible_message!/1` creates a `ConversationGroupAccess` only when the inserted message is the conversation root. For replies, callers must already have inserted the root and its grant, but the function name and module documentation can be read as guaranteeing accessible state for every invocation.
   - This is test-maintenance polish rather than a product defect. Make the precondition explicit in documentation, or split root and reply construction into separately named helpers.

## Judgement-worthy non-blocking code-health findings

1. **Projection fixtures can construct states that production projectors should not permit**
   - **File:** `web/test/support/messaging_fixtures.ex`
   - **Smell:** The fixture inserts `Message` and `ConversationGroupAccess` records directly. A reply can therefore be inserted without an existing root grant, and literals such as `"write"` duplicate projection vocabulary outside the projector/schema boundary.
   - **Why human judgement may be useful:** Direct read-model fixtures are efficient and appropriate for query-focused tests, but they can hide drift between projector behavior and query-test setup. The team may want to retain this speed while providing stricter root/reply helpers or schema-owned access-level constructors.

2. **Test database capacity is coupled to a fixed projector-concurrency floor**
   - **File:** `web/config/test.exs`
   - **Smell:** The scheduler-derived Repo pool now has a minimum of 16 connections to prevent SQL Sandbox starvation when several projectors need to acknowledge events.
   - **Why human judgement may be useful:** This is a practical and apparently effective sandbox fix, especially on single-scheduler environments, but the number is coupled to current process/projector concurrency and may become stale. A future test-infrastructure pass could derive or document the required capacity, or improve ownership/lifecycle coordination instead of relying on a fixed floor.
   - The supplied workflow evidence also indicates this adjustment was initially present as a working-tree modification rather than in the reviewed `19a51a338fa1e414391d184d264ab4a5cce73b7c..HEAD` commit range. It should be included in the final committed state if it remains necessary for the validated test behavior.

3. **Known redundant delivery to an Admin sender remains deferred**
   - **Area:** Messaging recipient selection for Admin-group root messages
   - **Smell:** An active Admin who originates an Admin conversation receives a redundant root-message copy.
   - **Why human judgement may be useful:** The plan explicitly accepts and defers this behavior, so it is not a merge blocker. Changing it later requires a product decision about whether sender copies are delivery records, mailbox copies, or both; it should not be “cleaned up” incidentally.

## Suggested fixes

1. Update `Memba.MessagingFixtures` documentation to state that:
   - root insertion creates the conversation access grant; and
   - reply insertion assumes the root and grant already exist.

2. Prefer distinct fixture entry points such as:
   - `insert_group_accessible_root_message!/1`
   - `insert_reply_message!/1`

   The reply helper can require an existing conversation ID and, if useful, assert that the corresponding group grant exists.

3. Document why the test Repo requires at least 16 connections and what concurrency it accommodates. Ensure the `web/config/test.exs` change is included in the final commit rather than relying on an uncommitted validation-only change.

## Validation notes

- The sandbox runtime preflight passed.
- The final `dev ci` stage succeeded.
- The quick suite reported **1,129 tests with 0 failures**.
- Browser acceptance completed with **122 scenarios and 877 steps passing**.
- Focused validation of `MembaWeb.DevTestSupportControllerTest` passed after the test Repo pool adjustment.
- The supplied results include the relevant Admin messaging, inbound-email/reply, group access, slug, and existing Everyone-surface regressions.
- No evidence indicates that acceptance scenario wording was changed to accommodate the implementation; planned runner-debt tag narrowing is compatible with preserving the scenarios as acceptance criteria.
