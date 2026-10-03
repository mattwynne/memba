{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5a0be69826405522dbbc727b73e11cb5eac89784",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
      "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
      "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
        "origin": "Adapter-completion portion of approved implementation step 4, corrected after review to distinguish valid broad scopes from malformed known notifications.",
        "status": "prepared",
        "coverage": [
          "All actual event families published by the eleven in-scope projectors",
          "Exact collection, identity and authorization invalidations for valid complete events",
          "Only evidenced broader scopes for valid events, including MessageSent club-conversation scope and role/permission fan-out",
          "Legacy MemberRemoved scope recovery from an evidenced committed source, currently the retained membership row",
          "Visible contract violations for unsupported projector/event pairings and missing required identities",
          "ConversationFollow MessageSent true/default behavior and false no-op behavior",
          "Replay-only EmailDeliveryOpened no-op behavior for both delivery projectors",
          "Exact tuple matching and unrelated-projector isolation",
          "Fresh independent review after focused validation"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
          "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
        ],
        "candidate_origins": [
          {
            "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
            "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
            "packet_id": "task-008a-0b2466f-adapter-matrix-1",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
          }
        ]
      },
      {
        "task_id": "task-008b",
        "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
        "status": "pending",
        "coverage": [
          "One coherent group-creation context result",
          "Fresh active-club, current-member and manage-members authorization reads",
          "Selected Club, current membership, Person, role and permission interests",
          "No ownership of generated group identity, typed name, preview, errors or command state"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008c",
        "todo_line": "- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
        "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
        "status": "pending",
        "coverage": [
          "One coherent settings result",
          "Fresh selected-club membership and current-Person resolution",
          "Current Person active-club membership and email-address collections",
          "Selected and represented Club identities",
          "No ownership of tab, add-email form, errors or command feedback"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008d",
        "todo_line": "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
        "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
        "status": "pending",
        "coverage": [
          "One coherent compose-context result",
          "Fresh active-club, current-member and selected-audience participation reads",
          "Club-member, participating-group and selected-group-member collection interests",
          "Represented Person and primary-email eligibility interests",
          "No ownership of subject, body, validation, retry or send state"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008e",
        "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
        "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
        "status": "pending",
        "coverage": [
          "One coherent authorized delivery-detail result",
          "Fresh active-club, current-member, group-participation and conversation-access reads",
          "Exact conversation, represented Person, delivery collection and delivery identity interests",
          "Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence",
          "No ownership of route, disclosure, flash or navigation state"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008f",
        "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
        "status": "pending",
        "coverage": [
          "One coherent invitation context result",
          "Fresh active-club, current-member and manage-members authorization reads",
          "Club-member collection entry and exit for the displayed count",
          "Selected Club, current membership, Person, role and permission interests",
          "No ownership of invitation email, validation, resend decision, delivery feedback or navigation"
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
          "Preserved routes, access transitions, forms, commands, navigation and UI",
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
    "candidate_origins": [
      {
        "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
        "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
        "packet_id": "task-008a-0b2466f-adapter-matrix-1",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
      }
    ],
    "coverage_map": [
      {
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
        ],
        "pending_task_ids": [],
        "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, proof inventory and explicit exclusions."
      },
      {
        "accepted_task_lines": [
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
        ],
        "pending_task_ids": [],
        "scope": "Accepted dashboard query boundary, fresh-authority prerequisite, coherent dashboard assign and connected subscribe-before-read ordering."
      },
      {
        "accepted_task_lines": [
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
        ],
        "pending_task_ids": [],
        "scope": "Accepted provisional lifecycle, matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
      },
      {
        "accepted_task_lines": [
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
        ],
        "pending_task_ids": [],
        "scope": "Accepted dashboard binding, scoped invalidation and open-dashboard vertical behavior proof."
      },
      {
        "accepted_task_lines": [
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
        ],
        "pending_task_ids": [],
        "scope": "Accepted conversation-detail binding, multi-projector convergence, fresh-access proof and frozen extraction contract."
      },
      {
        "accepted_task_lines": [
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
        ],
        "pending_task_ids": [],
        "scope": "Accepted stakeholder scenario and committed-membership-projector-to-open-member-LiveView proof."
      },
      {
        "accepted_task_lines": [
          "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."
        ],
        "pending_task_ids": [],
        "scope": "Accepted standalone generic package and package-owned lifecycle, matching, race and cleanup tests."
      },
      {
        "accepted_task_lines": [
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
        ],
        "pending_task_ids": [],
        "scope": "Accepted package adoption by dashboard and conversation-detail while retaining application-owned policy."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008a"
        ],
        "scope": "Correct and prove the app-owned notification adapter against actual projector/event families, evidenced broad scopes, no-op publications and visible malformed-event contract violations."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008b",
          "task-008c",
          "task-008d",
          "task-008e",
          "task-008f"
        ],
        "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009"
        ],
        "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence."
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
    "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line. Its rejected candidate is still present at current HEAD: the adapter and focused-test blobs match the rejected candidate, so this remains a revision with the required candidate origin. The preceding planner packet was not dispatched because its pending obligation used the invalid status `prepared_revision`; this handoff uses `prepared` while retaining `attempt: revision` and a fresh packet identity. The approved plan, corrected migration matrix and current todo supersede the latest review’s proposed Membership club fallback and synthetic partial-event fallback requests: known events missing required identities must produce a visible contract violation, and broader invalidation is retained only for evidenced valid shapes. Direct projector inspection also shows that current committed changes do not establish the synthetic nested membership-scope recovery tested by the rejected candidate, so the worker may retain changes-based recovery only if concrete historical publisher evidence is first demonstrated; the retained membership row is the currently evidenced legacy MemberRemoved recovery path. The Club projector’s compatibility publications are limited to its actual Group and Role clauses and do not include membership-removal events. No todo edit is needed because the current 008A line already records the corrected contract and fresh-review requirement. The sole approved acceptance scenario is already accepted and green; adapter classification has no separate agreed scenario, so focused technical proof is used with scenario_focus null."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5a0be69826405522dbbc727b73e11cb5eac89784",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5a0be69826405522dbbc727b73e11cb5eac89784",
    "outcome": "Correct the existing app-owned notification classifier and its focused tests so every actual in-scope projector/event pairing produces the corrected matrix’s exact or evidenced broad invalidations, projector no-op publications are ignored, and unsupported pairings or missing required identities surface a visible contract violation without refreshing unrelated queries.",
    "scope": [
      "Revise `MembaWeb.LiveQuery.MembaReadModelSource` to dispatch by actual event-struct and projector pairing for the eleven in-scope projector families, while keeping unrelated projector modules and malformed outer notification envelopes ignored.",
      "Retain exact collection and identity invalidations for valid Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow and both delivery-projector event families.",
      "For the Club projector, support only ClubCreated and ClubUpdated plus its actual no-op compatibility publications: GroupCreated, GroupEmailSlugAssigned, ClubRoleDefined, ClubRolePermissionGranted, ClubRoleAssignedToMember, MemberRoleAssigned, ClubRoleRemovedFromMember and MemberRoleRemoved. Do not accept ClubMemberRemoved or MemberRemoved as Club-projector publications.",
      "Retain only evidenced broader valid scopes: MessageSent’s club-conversation collection because the event has no audience group, role/permission fan-out, membership-removal role/permission invalidation without inventing a role ID, exact Person interests without club scope, and the Club projector’s actual Group and Role compatibility publications.",
      "Recover omitted club/person scope only for genuine legacy MemberRemoved compatibility. Use the retained membership row as the currently evidenced recovery path; retain committed-changes recovery only if concrete historical publisher output demonstrates that shape, not from synthetic nested maps. If required identity remains unavailable, surface an app-owned, testable contract violation and emit no partial or fallback invalidation.",
      "Make ConversationFollow classify default or true `MessageSent` as an exact follow change and return `:ignore` for `sender_follows_conversation: false`, matching the projector’s no-op branch.",
      "Map EmailDeliveryCreated, EmailDeliveryDelivered, EmailDeliveryDelayed, EmailDeliveryBounced and EmailDeliverySpamComplaint from both delivery projectors to identical exact message-delivery and delivery identities; return `:ignore` for replay-only EmailDeliveryOpened.",
      "Remove unsupported delivery committed-change recovery, projection-row lookup and global fallback behavior, together with synthetic partial-map fallback expectations that the corrected matrix identifies as malformed rather than historical valid variants.",
      "Update the focused adapter suite with actual event structs and explicit regression proof for exact mappings, legitimate broad scopes, no-op events, legacy row recovery, visible contract failures, unsupported projector/event pairings, exact unrelated-scope isolation and ignored unrelated input.",
      "Return a concise eleven-row projector/event-family coverage table as completion evidence so fresh independent review can compare implementation and tests directly with the corrected matrix."
    ],
    "scope_exclusions": [
      "Do not add tasks 008B through 008F query modules or migrate any remaining LiveView.",
      "Do not modify the generic `LiveQuery.Query`, `LiveQuery.Source` or `LiveQuery.Binding` package API or implementation; contract-violation signaling remains application-owned.",
      "Do not change accepted dashboard or conversation-detail query vocabulary except to report an unavoidable conflict before proceeding.",
      "Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms, UI behavior or staff stream-backed views.",
      "Do not edit the approved plan, corrected migration matrix, todo, ADRs, acceptance feature or accepted package documentation.",
      "Do not preserve synthetic partial-map or committed-change fallbacks merely because the rejected candidate tested them; classify according to actual current and evidenced legacy publisher paths.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario; this technical revision has no appropriate agreed red scenario.",
      "Do not perform tasks 010 or 011 integration/final-gate work and do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.",
      "Do not mark task 008A complete; the deterministic independent review owns acceptance."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model permits broader invalidation only for a valid published event that genuinely lacks exact scope. Unsupported events and known events missing required identities must not silently become fallback cases; Membership with club scope but no recoverable Person identity must surface a contract violation."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation and explicitly requires actual event-family coverage, malformed Membership contract violations, a corrected fallback audit and fresh independent review."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The guard requires preservation of the rejected task-008a candidate origin and identifies the previous undelivered packet, while the new packet must bind to current HEAD rather than the baseline artifact’s pre_planner_head."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The rejected candidate changed only the Memba adapter and its focused test, reported 27 adapter tests and 8 query-vocabulary tests passing, and claimed broad fallback and row-recovery behavior that the corrected matrix no longer permits."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review rejected task 008A because Membership fallback scope refreshed unrelated clubs, false sender_follows_conversation still invalidated follow state, several expected branches lacked proof, and no projector/event coverage table was supplied. The corrected approved contract supersedes the review’s requested synthetic fallback remedies but not its observed defects or evidence gap."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The normative event map distinguishes actual exact events, legitimate broad collection scopes, replay/no-op publications and malformed payloads. It permits genuine legacy MemberRemoved recovery, requires false auto-follow and EmailDeliveryOpened no-ops, and rejects unsupported missing-ID and delivery-row-lookup fallbacks."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "The adapter receives post-transaction `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` notifications from projector after_update/3; classification operates at this committed boundary."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Memba owns query interests and notification translation, while relevant invalidations trigger fresh authorized reads instead of patching view-model fields from events."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Current HEAD contains the rejected classifier. It dispatches mainly by projector, accepts arbitrary event maps, emits global fallbacks for malformed inputs, classifies false auto-follow sends, performs unsupported delivery committed-change and row recovery, and classifies replay-only opened events as delivery changes."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "Current tests cover the eleven projectors but also lock synthetic partial-map fallbacks, synthetic membership changes recovery, delivery row recovery/global fallback and normal EmailDeliveryOpened invalidation. They lack false auto-follow, corrected contract-violation and exact Club compatibility-boundary proof."
      },
      {
        "path": "web/lib/memba/membership/projectors/club.ex",
        "facts": "The Club projector publishes ClubCreated and ClubUpdated plus GroupCreated, GroupEmailSlugAssigned and eight Role compatibility clauses. It has no ClubMemberRemoved or MemberRemoved compatibility clause."
      },
      {
        "path": "web/lib/memba/membership/projectors/membership.ex",
        "facts": "The Membership projector handles current ClubMemberAdded/Removed and legacy MemberAdded/Removed. Its removal operations do not produce the synthetic nested membership-scope committed-change shape used by current tests; the retained projection row is the evidenced legacy recovery source."
      },
      {
        "path": "web/lib/memba/membership/projectors/role.ex",
        "facts": "Role publishes definition, permission, current/legacy exact assignment/removal and membership-removal compatibility events. Membership removal invalidates all roles and permissions without a fabricated role ID; its current Ecto operations do not establish the synthetic changes-based scope used by the rejected candidate."
      },
      {
        "path": "web/lib/memba/messaging/projectors/conversation_follow.ex",
        "facts": "The projector calls MessageSent.sender_follows_conversation?/1; false leaves the Ecto.Multi unchanged even though after_update/3 still publishes, so the adapter must ignore that no-op notification."
      },
      {
        "path": "web/lib/memba/messaging/events/message_sent.ex",
        "facts": "sender_follows_conversation defaults true and the event helper returns false only for an explicit false value; focused tests must cover default/true invalidation and false no-op behavior."
      },
      {
        "path": "web/lib/memba/messaging/projectors/member_email_delivery.ex",
        "facts": "Created, delivered, delayed, bounced and spam-complaint events alter member-facing delivery state. EmailDeliveryOpened is a deprecated replay-only no-op, and every state-changing event struct carries message and delivery IDs."
      },
      {
        "path": "web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex",
        "facts": "The staff delivery projector independently changes the joined reason/status contributor for the same five state-changing families. EmailDeliveryOpened is likewise a replay-only no-op and state-changing events carry exact IDs."
      },
      {
        "path": "packages/live_query/lib/live_query/source.ex",
        "facts": "The generic source treats Memba invalidations as opaque and declares only ignore or successful invalidation classification. Keep the package unchanged and use a stable application-owned failure for recognized malformed notifications."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "Normal source results are ignored or matched for refresh. The revision must not broaden the frozen package contract merely to represent an application publisher-contract violation."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The accepted dashboard query consumes exact Memba tuple interests and legitimate collection scopes; valid-event tuple vocabulary must remain compatible while malformed-event fallbacks are removed."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "The accepted conversation-detail query consumes exact conversation, message, follow, Person and delivery interests. Both state-changing delivery projectors must continue producing the same exact delivery vocabulary."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests must remain deterministic, avoid sleeps and liveness polling, and use supervised cleanup for any started processes."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The iteration’s sole approved scenario, Bob sees Alice join without reloading, is already green with its predicted outcome matched; this adapter revision must not fabricate another scenario-first cycle."
      }
    ],
    "constraints": [
      "Keep implementation changes limited to `web/lib/memba_web/live_query/memba_read_model_source.ex` and `web/test/memba_web/live_query/memba_read_model_source_test.exs` unless a direct compile requirement proves another path unavoidable; report that conflict before expanding scope.",
      "Use actual event structs and actual projector/event pairings as ground truth. Narrow maps may test malformed outer envelopes but must not establish invented valid event variants.",
      "Keep unrelated projector modules and malformed outer notification envelopes as `:ignore`; distinguish those from recognized in-scope projector/event contract violations.",
      "A recognized pairing missing a required identity must produce a visible, stable, testable application-owned failure and must not return exact-looking partial keys or scoped/global fallback keys.",
      "Do not replace precise invalidations with unconditional global invalidation. Preserve exact tuple equality and legitimate collection-entry/exit scopes.",
      "Keep current and legacy membership, role assignment/removal and Club compatibility paths explicit; recover only historically evidenced omissions and never invent role IDs.",
      "Do not treat arbitrary `changes` maps as historical evidence. If retaining any changes-based identity recovery, demonstrate the concrete projector or serialized legacy shape that produces it.",
      "Treat duplicate and out-of-order valid notifications as harmless reread hints and never patch query results from source events.",
      "Both delivery projectors independently contribute to one joined result and must emit compatible exact keys for state-changing events; replay-only opened events must not imply a status transition.",
      "Keep Memba projector/event knowledge, failure types and tuple vocabulary out of `packages/live_query`.",
      "Prepare evidence for fresh independent review and do not mark the todo line accepted."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs",
      "if grep -R -n -E 'Memba|Commanded' packages/live_query --exclude-dir=_build --exclude-dir=deps --exclude-dir=node_modules; then exit 1; else echo 'packages/live_query has no Memba or Commanded references'; fi",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and summarize each classifier or focused-test change.",
      "Provide a concise table with one row per in-scope projector, listing actual source-event families, exact or legitimate broad invalidations, no-op events, any evidenced recovery path and malformed/unsupported behavior.",
      "Report successful exit status and test count for the focused adapter test command.",
      "Report successful exit status and test count for the accepted dashboard and conversation-detail query-vocabulary regression command.",
      "Show focused proof that a Membership notification with club scope and unrecoverable Person identity surfaces the chosen visible contract violation and emits no scoped or global Membership fallback.",
      "Show focused proof that legacy MemberRemoved recovery uses an evidenced source, and identify that source; do not claim arbitrary committed changes as evidence.",
      "Show focused proof that the Club projector accepts only its actual Club, Group and Role compatibility families and rejects membership-removal or other unsupported pairings visibly.",
      "Show focused proof that default/true auto-following MessageSent invalidates exact follow state while `sender_follows_conversation: false` is ignored.",
      "Show focused proof that both delivery projectors emit identical exact keys for five state-changing families and ignore replay-only EmailDeliveryOpened, with no committed-change recovery, row lookup or global delivery fallback retained.",
      "Confirm exact unrelated club, group, conversation, Person, message and delivery identities remain isolated and unrelated projectors or malformed outer envelopes remain ignored.",
      "Confirm no Memba or Commanded dependency or application-specific contract was added to `packages/live_query`, and report formatting and diff-check results.",
      "Report any actual projector/event family that cannot satisfy the corrected matrix without changing an accepted boundary; leave the todo unchecked if such a conflict remains."
    ],
    "candidate_origins": [
      {
        "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
        "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
        "packet_id": "task-008a-0b2466f-adapter-matrix-1",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
      }
    ],
    "scenario_focus": null
  }
}