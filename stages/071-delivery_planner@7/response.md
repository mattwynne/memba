{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e9eec549366fe78698d147e0e6eb0d71cde1e621",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
      "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
      "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
      "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
      "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
      "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
      "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
      "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
      "- [x] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008f",
        "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
        "status": "prepared",
        "coverage": [
          "One coherent invitation context result containing selected Club, current member and active-member count",
          "Fresh normalized-email, active-club, current-Person, current-member and manage-members authorization reads on every load",
          "Selected-club member collection entry and exit coverage for the displayed count",
          "Exact selected Club, current membership, current Person, selected-club authority, current-member role and manage-members permission interests",
          "Preserved forbidden semantics and no ownership of invitation email, validation, resend decision, delivery feedback, command, route, flash or navigation state"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
        "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
        "status": "pending",
        "coverage": [
          "Group creation, settings, message composition, delivery detail and invitation LiveViews",
          "One coherent result assign per remaining in-scope page",
          "Preserved routes, access transitions, transient state, commands, navigation and UI",
          "Live delivery status and staff-reason convergence",
          "Existing conversation and delivery behavior",
          "No staff stream migration"
        ],
        "replaces": [
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
        "origin": "Approved implementation step 6.",
        "status": "pending",
        "coverage": [
          "Path dependency integration in web/mix.exs",
          "Production Docker build and release inclusion",
          "Package tests exercised by dev check in supported environments"
        ],
        "replaces": [
          "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
        "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
        "status": "pending",
        "coverage": [
          "Focused proof for every migrated member page",
          "Residual package lifecycle and bind/reconnect race coverage",
          "Final full dev check on the exact clean or staged state"
        ],
        "replaces": [
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
          "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
        ],
        "candidate_origins": []
      }
    ],
    "candidate_origins": [],
    "coverage_map": [
      {
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
          "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
          "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
          "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
          "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
          "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
          "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
          "- [x] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract and package extraction, committed-read-model adapter audit, and all accepted view-specific query prerequisites through delivery detail."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008f"
        ],
        "scope": "Introduce the remaining fresh-authorized invitation query boundary with selected-club member-count and manage-members invalidation interests while excluding LiveView-owned state."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009"
        ],
        "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, commands, navigation, UI and delivery/conversation convergence."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-010"
        ],
        "scope": "Complete production package, Docker release and repository quality-gate integration."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011"
        ],
        "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation."
      }
    ],
    "planner_note": "The binding checkpoint for this planner visit is current HEAD e9eec549366fe78698d147e0e6eb0d71cde1e621. The trusted baseline and checked todo preserve task 008E as accepted after its bounded worker result and independent accepting review; no unaccepted candidate origin remains. The first unchecked line, task 008F, is already a bounded query-only prerequisite and needs no todo rewrite or further split. Direct inspection shows that the invitation surface needs exactly selected Club, current member and active-member count, while the accepted group-creation query, Membership read APIs and audited notification adapter provide the fresh-authority and interest patterns. This packet creates only the app-owned query and focused tests; LiveView binding, subscribe-before-read behavior, access-loss navigation, form preservation, bind races and reconnect proof remain in tasks 009 and 011. The invitation query uses exact selected-club authority rather than the Person-wide active-clubs collection so a membership change for the same Person in another club remains unrelated. The only approved acceptance scenario is already accepted and green and does not exercise this standalone query boundary, so scenario_focus is null rather than resetting accepted work or inventing another scenario. Final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e9eec549366fe78698d147e0e6eb0d71cde1e621",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008f-e9eec54-invitation-context-query-1",
    "task_id": "task-008f",
    "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e9eec549366fe78698d147e0e6eb0d71cde1e621",
    "outcome": "Add one app-owned fresh-authorized invitation-context live query that returns exactly the selected Club, current member and active-member count needed by the member invitation surface, with selected-club collection and exact authority interests that let a later binding update the count and recheck manage-members access without replacing invitation form or command state.",
    "scope": [
      "Add `MembaWeb.MemberInvitationQuery` in `web/lib/memba_web/member_invitation_query.ex` and focused coverage in `web/test/memba_web/member_invitation_query_test.exs`; follow the accepted app-owned `LiveQuery.Query` descriptor pattern without wiring the LiveView yet.",
      "Give the descriptor stable `club_id` and `authenticated_email` inputs, query ID `:member_invitation`, and one `:invitation_context` result assign.",
      "On every load, normalize the authenticated email, reread active clubs, resolve the routed selected Club, reread the current Person, resolve the active selected-club member by Person ID, and rerun `Authorization.authorize_manage_members/2`; do not consume mount-captured `current_identity_clubs` or a previously assigned member.",
      "Preserve the invitation surface's existing fail-closed contract: missing, invalid, inactive, foreign-club, unresolved-identity, inactive-member and unauthorized contexts return `{:error, :forbidden}`.",
      "Return one coherent result with exactly `selected_club`, `current_member`, and `active_member_count`, using the existing active-club-member read API for the selected-club count.",
      "Return the selected Club identity, selected-club member collection, exact current membership, current Person, exact selected-club Person relationship, exact current-member role and permission relationships, and same-club role/permission collection interests needed by the accepted adapter.",
      "Keep the invitation interest set selected-club scoped: do not add the Person-wide `person_clubs` collection, represented interests for every counted member, or interests for invitations, messages, groups, conversations or deliveries.",
      "Prove normalized primary and attached-email authentication resolve the current member by Person ID rather than by comparing the authenticated address with the member's primary email.",
      "Prove fresh reads change `active_member_count` when another member enters or leaves the selected club, while the same Person's membership change in another club and unrelated Club, Person, membership and role notifications do not match this query.",
      "Prove fresh selected-membership or manage-members permission loss returns `{:error, :forbidden}` and that the successful result excludes invitation email, validation, pending/resend decision, delivery feedback, command result, route, flash and navigation state.",
      "Exercise representative committed-source classifications against the query interests for selected Club, selected-club membership collection, exact current membership/relationship, current Person, exact current-member role/permission and same-club permission invalidations."
    ],
    "scope_exclusions": [
      "Do not change `MembaWeb.MemberInvitationLive.New`, its rendering, existing LiveView tests, mount behavior, form handling, submission behavior, flash, return navigation or authorization transitions; binding and migration remain in task 009.",
      "Do not wire `LiveQuery.Binding`, subscribe to PubSub, add notification handlers or implement the connected access-loss transition in this query-only task.",
      "Do not add bind-window race, reconnect, open-page count, form-preservation or committed-projector-to-open-LiveView tests; remaining lifecycle and page proof belongs to tasks 009 and 011.",
      "Do not change the accepted `MembaWeb.MemberGroupCreationQuery`, other accepted queries, the generic package, `MembaWeb.LiveQuery.MembaReadModelSource`, read APIs, projector handlers, event shapes, projections, schemas, commands, routes or invitation-domain policy.",
      "Do not add `{:person_clubs, person_id}` merely because active clubs are reread; the invitation result represents one routed club, and exact `{:person_club, club_id, person_id}` invalidation covers its authority transition without unrelated-club refreshes.",
      "Do not register represented Person, role or permission interests for every counted member; the public result represents only the current member and a count, whose entry/exit dependency is covered by `{:club_members, club_id}`.",
      "Do not implement remaining LiveView migration, package integration, final proof or any later todo obligation.",
      "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate.",
      "Leave task 008F unchecked and return one candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved model requires one coherent authorized result per query, fresh authorization on every refresh, collection interests for absent-row entry and exit, exact isolation from unrelated updates, and exclusion of transient LiveView state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008F is the first unchecked line and asks only for the fresh-authorized invitation context query plus focused tests; LiveView migration, package integration and final validation remain later obligations."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint preserves every checked line through task 008E, identifies 008F as the first pending obligation, and requires no unaccepted candidate origin to be carried into this packet."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest worker result completed only the accepted delivery-detail query candidate in two files, reported its focused checks passing, and left no unresolved item or candidate provenance relevant to the invitation query."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted task 008E and confirmed that no candidate provenance remains, making 008F a fresh implementation rather than a revision."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The only approved acceptance scenario, `Bob sees Alice join without reloading`, is already green and belongs to accepted task 006A; it must not be reset for this standalone technical query."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The invitation row requires selected Club, current member and active-member count under one result; selected-club member entry/exit changes the count, current membership/role/permission changes recheck access, and form, validation, resend, feedback and navigation stay LiveView-owned."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract requires a stable query identity, exactly one public result assign, a one-argument loader returning result plus complete opaque interests or an access error, and no ownership of form or navigation state."
      },
      {
        "path": "web/lib/memba_web/live/member_invitation_live/new.ex",
        "facts": "The current `invitation_context/3` establishes the existing selected-club/current-member/count result and forbidden semantics, but resolves authority from mount-captured clubs and has no live-query subscription."
      },
      {
        "path": "web/test/memba_web/live/member_invitation_live/new_test.exs",
        "facts": "Current page tests lock routed-club selection, current-member presentation, active-member count, manage-members mount authorization, group-aware return links and signed-out behavior; the query-only candidate must preserve that data contract without editing the page."
      },
      {
        "path": "web/lib/memba_web/member_group_creation_query.ex",
        "facts": "The closest accepted query demonstrates the descriptor shape, normalized-email fresh active-club and Person resolution, current-member lookup by Person ID, manage-members authorization and exact member/role/permission interest vocabulary."
      },
      {
        "path": "web/test/memba_web/member_group_creation_query_test.exs",
        "facts": "Accepted focused proof demonstrates attached-email identity resolution, fresh membership and permission loss, fail-closed invalid inputs, exact result keys and exclusion of transient form and command state."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`list_active_members_of_club/1` returns selected-club members with membership and Person identity in deterministic order and is the existing invitation surface's read API for current-member resolution and active-member count."
      },
      {
        "path": "web/lib/memba/membership/authorization.ex",
        "facts": "`authorize_manage_members/2` checks the projected `club.manage_members` permission for a club and Person and returns an unauthorized error when current permission is absent."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted adapter emits exact Club, selected-club member collection, membership, Person/club, Person, member-role, member-permission, club-role and club-permission invalidations, with equality-based matching and unrelated-scope isolation."
      },
      {
        "path": "packages/live_query/lib/live_query/query.ex",
        "facts": "`LiveQuery.Query` requires a stable ID, atom assign and one-argument loader returning `{:ok, result, interests}` or `{:error, reason}`; Memba-specific interest values remain opaque to the package."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps authorized Memba query composition in the app, puts only generic binding mechanics in the local package, and replaces one coherent result assign after matching committed changes."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Read-model notifications are published after projector transactions commit, making fresh projection reads the correct response to a matching invalidation."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use focused file-level ExUnit coverage and deterministic synchronization, avoiding sleeps and broad unrelated test commands."
      }
    ],
    "constraints": [
      "Keep implementation changes limited to `web/lib/memba_web/member_invitation_query.ex` and `web/test/memba_web/member_invitation_query_test.exs`.",
      "Use query ID `:member_invitation`, assign `:invitation_context`, stable `club_id` and `authenticated_email` inputs, and a one-argument descriptor loader returning `{:ok, result, interests}` or `{:error, :forbidden}`.",
      "Every load must normalize the authenticated email and freshly resolve active clubs, current Person, selected-club membership, member count and manage-members authority from accepted read APIs.",
      "Resolve the current member by current Person ID so an attached authenticated email still selects the member whose projection exposes a different primary email.",
      "Return exactly `selected_club`, `current_member`, and `active_member_count`; do not expose the loaded member collection or transient LiveView state.",
      "Register `club`, `club_members`, `membership`, `person`, exact `person_club`, exact `member_roles`, exact `member_permissions`, `club_roles`, and `club_permissions` interests for the successful context.",
      "Do not register the broad `person_clubs` interest; a current Person membership change in another club must remain isolated from this selected-club query.",
      "Use actual adapter event structs for notification-intersection proof; do not invent partial events or weaken malformed-event handling.",
      "Preserve the existing invitation `:forbidden` result for every missing or unauthorized context.",
      "Leave task 008F unchecked and return one bounded candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_invitation_query_test.exs test/memba_web/member_group_creation_query_test.exs test/memba_web/live/member_invitation_live/new_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm implementation changes are limited to `web/lib/memba_web/member_invitation_query.ex` and `web/test/memba_web/member_invitation_query_test.exs`.",
      "Report the final descriptor ID, assign and stable input shape, plus the exact three successful-result keys.",
      "Explain how every load normalizes identity, rereads active clubs, resolves the current Person and selected-club member by Person ID, counts active members and rechecks manage-members permission.",
      "Report proof that normalized primary and attached-email authentication both resolve the correct current member.",
      "List the complete successful-result interest set and map each interest to the accepted Club, Membership, Person or Role source invalidations.",
      "Report proof that another selected-club member entering or leaving changes the count on a fresh read.",
      "Report proof that selected membership loss and manage-members permission loss return `{:error, :forbidden}`.",
      "Report proof that missing, invalid, inactive, foreign-club and unresolved-identity contexts fail closed.",
      "Report proof that selected-club Membership, current Person, exact role/permission and same-club permission notifications match while unrelated clubs, Persons, memberships and roles do not.",
      "Confirm that a Membership change for the same Person in another club does not match and that no `person_clubs` interest is registered.",
      "Confirm the result contains no invitation email, form, errors, pending/resend decision, delivery feedback, command result, route params, flash or navigation state.",
      "Report successful exit status, test count and failure count for the combined focused query, accepted authorization-query, current invitation-page and source-adapter command.",
      "Report successful format and diff checks.",
      "Confirm no LiveView wiring, existing query, adapter, package, read API, projector, schema, command, event, route, plan, todo, matrix, ADR, acceptance feature or delivery metadata changed, and task 008F remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}