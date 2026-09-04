# Iteration 057 Plan Review — Admin Group Email Conversations

I read the complete plan file (`docs/iterations/057-admin-group-email-conversations/plan.md`, 243 lines) directly, cross-checked it against the acceptance feature files it names, its stated dependency (iteration 056), the referenced problem notes, the groups vision doc, and the current codebase state.

## Decision: READY
## Confidence: High

## Blocking gaps

None found. The plan is internally consistent, its scope is bounded, its acceptance criteria are concrete and testable, its BDD classification and feature-file plan are already reflected verbatim in `acceptance-tests/features/member_message_deliverability.feature` (lines 84–101) and `acceptance-tests/features/club_message_replies.feature` (lines 120–133) with matching `@iteration-057 @todo-domain @todo-ui` tags, and its hard dependency on iteration 056 is explicitly named, verified as not-yet-merged (056's status is `implementing`, and no `GroupCreated`/`GroupMemberAdded`/`SystemGroupMembership`/`ConversationAccessGrantedToGroup` code exists yet), and handled by an explicit "verify 056 first" step (Implementation Plan step 1) plus a named risk ("Iteration 056 is a hard dependency and must be merged before this plan can start"). This matches the project's own status semantics (`docs/iterations/README.md`: a `validated` plan may wait behind the single WIP slot), so the dependency is a sequencing fact the plan already accounts for, not a plan-quality defect.

## Non-blocking improvements

1. The Implementation Plan (steps 1–10) never includes updating `docs/specs/2026-09-02-groups-and-conversation-access-vision.md` to reflect the confirmed `club_members_only` posting rule — it's only mentioned as a Risk/Follow-up. Consider promoting it to an explicit implementation step so it isn't dropped during delivery.
2. Technical steps are slightly less concrete than iteration 056's plan about which existing files change (e.g., step 4's "inbound destination resolution" almost certainly means `web/lib/memba/messaging/inbound_club_destination.ex`, and related `inbound_club_authorization.ex`/`inbound_club_sender.ex`/`inbound_club_rejection_email.ex`). Naming these explicitly would speed delivery and reduce discovery time.
3. "Add public Messaging queries" (step 8) doesn't name a target module/namespace; a suggested location (mirroring the Membership group-lookup API pattern from 056) would tighten the interface contract.
4. The new email-slug column/migration for groups isn't named (e.g., column name, migration filename), unlike 056's explicit `membership_groups`/`membership_group_memberships` naming.

## Smallest viable iteration

The plan is already close to the minimum useful vertical slice: it deliberately excludes web UI, custom groups, configurable policies, and the redundant-copy fix, while still shipping the one end-to-end capability that matters (email-only, private Admin conversations). I would not shrink it further — splitting the email-slug model from the Admin route, or splitting inbound-post from reply-by-email, would leave an unusable half-slice. This is an appropriately minimal, coherent unit.

## Required plan edits

None required for readiness. Optional (see non-blocking improvements above): add an explicit implementation step for the vision-doc update, and name the specific existing Messaging modules/files expected to change.

## Validation plan (how to prove the iteration succeeded)

- Confirm iteration 056 is merged and its Membership group/membership queries, conversation access grant, and group-aware reply authorisation are present and passing before starting 057's own work (already specified as step 1).
- Run the plan's own Validation Plan: focused Membership tests (slug persistence/uniqueness/backfill/replay), focused Messaging tests (destination resolution, recipient delivery, sender policy, access grants, reply authorisation), and existing inbound-email/reply regressions.
- Execute the three new `member_message_deliverability.feature` scenarios (non-Admin sender excluded, Admin sender included, other-club sender rejected) and the one new `club_message_replies.feature` scenario (Admin reply-by-email), removing/narrowing `@todo-domain`/`@todo-ui` only once each runner can execute them — confirmed these scenarios already exist in the repo exactly as the plan describes.
- Confirm group-ID-based Messaging queries return only the requested group's conversations, and that existing web surfaces still request Everyone only (no Admin leakage into UI).
- Run `dev check` on the committed implementation state as the final stop condition.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}