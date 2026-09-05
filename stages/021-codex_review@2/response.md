# Iteration 057 Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

None identified.

The implementation evidence is consistent with the accepted architecture and the project’s domain/CQRS/event-sourcing guidance:

- Group email slugs remain distinct from display names and deterministic system-group IDs.
- Commands and events remain the production write path; direct Ecto inserts are confined to read-model test fixtures.
- Conversation authorization is represented explicitly through projected conversation-to-group access grants.
- Provider/message identity remains the inbound-email idempotency boundary.
- `club_members_only` remains a named policy boundary rather than becoming an unplanned persisted setting.
- Existing member-facing surfaces remain scoped to Everyone while the read API becomes group-aware.

No evidence shows production code bypassing an ADR-mandated aggregate, event stream, projection, or messaging boundary.

## Blocking issues

None.

The two issues raised during synthesis have been addressed:

1. The projection fixture now documents that root insertion creates the access grant and that reply insertion requires an existing root and grant.
2. The Groups vision now distinguishes the new-conversation policy from reply authorization and reflects the accepted `club_members_only` behavior.

The failed `verify_review_repair` stage does not indicate a failed repair. The repair agent staged its changes, while the verifier compared only unstaged output from `git diff`; consequently it observed an empty working-tree diff. Subsequent evidence contains the repaired fixture documentation, and the final full check passed on the staged state.

## Bounded-safe fixes

None required before merge.

The potential fixture refactors suggested by earlier reviewers—separate root/reply helpers or schema-owned access-level constants—would be reasonable future cleanup, but are not necessary to make the current implementation safe or understandable.

## Judgement-worthy non-blocking code-health findings

1. **Direct read-model construction in tests**
   - **File:** `web/test/support/messaging_fixtures.ex`
   - **Smell:** `insert_group_accessible_message!/1` directly inserts `Message` and `ConversationGroupAccess` projection rows rather than exercising commands, events, and projectors.
   - **Why it may need human judgement:** This is appropriate for fast query/web tests, and the fixture contract is now documented. However, such fixtures can drift from production projector behavior. Domain and projector behavior should continue to be covered separately through the real command/event path.

2. **Implicit root-message convention in the fixture**
   - **File:** `web/test/support/messaging_fixtures.ex`
   - **Smell:** Root detection depends on `message_id == conversation_id`; replies do not independently verify that their root and access grant exist.
   - **Why it may need human judgement:** The convention matches the existing model and is now explicit in documentation. Separate root and reply helpers could enforce stronger setup invariants, but would add test-support API surface and may not justify the churn yet.

3. **Fixed test Repo pool-size floor**
   - **File:** `web/config/test.exs`
   - **Smell:** Test database capacity has a fixed minimum of 16 connections to prevent SQL Sandbox starvation among concurrent Commanded projectors on single-scheduler environments.
   - **Why it may need human judgement:** The rationale is now documented and the change resolves a demonstrated failure. Nevertheless, the number is coupled to current projector concurrency and test lifecycle behavior. Future infrastructure changes may warrant deriving the requirement or improving sandbox ownership coordination.

4. **Redundant delivery to an Admin sender**
   - **Area:** Admin-group root-message recipient selection
   - **Smell:** An Admin who starts an Admin conversation receives a redundant root-message copy.
   - **Why it may need human judgement:** This is explicitly accepted and deferred by the iteration plan. Any later change should follow a product decision about sender-copy semantics rather than being treated as incidental deduplication.

## Suggested fixes

No pre-merge code changes are recommended.

As future maintenance:

- Consider separate fixture entry points for conversation roots and replies if invalid projection setups become a recurring testing problem.
- Revisit the test Repo pool floor if projector count, SQL Sandbox ownership, or CI topology changes.
- Preserve the explicitly deferred Admin-sender delivery behavior until product semantics are decided.

## Validation notes

- Sandbox runtime preflight passed.
- Final `dev ci`/`dev check` succeeded.
- The quick suite reported **1,129 tests and 0 failures**.
- Browser acceptance reported **122 scenarios and 877 steps passing**.
- Focused `MembaWeb.DevTestSupportControllerTest` validation passed after the Repo pool adjustment.
- The final full check ran after the review repairs.
- No acceptance feature files were changed by the repairs.
- The repaired changes are staged rather than committed; they should be included in the final commit.
- Confidence is **Medium**, rather than High, because the supplied implementation-evidence transcript is heavily truncated, limiting an independent line-by-line audit of every aggregate, projector, and authorization path. The green automated checks and convergent parallel reviews provide strong behavioral evidence despite that limitation.