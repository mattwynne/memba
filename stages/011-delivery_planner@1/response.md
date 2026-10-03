{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c0227b578a9196b34098aba0f76c6e163c155237",
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
        "status": "prepared",
        "origin": "Adapter-completion portion of approved implementation step 4, corrected through six independent review revisions and the explicitly delegated post-revision-6 selected-club authority repair.",
        "coverage": [
          "All actual event families published by the eleven source-recognized projectors",
          "Membership invalidations containing club-member collection, exact membership, exact selected-club authority and person-wide all-clubs keys",
          "Dashboard and conversation-detail selected-club authority interests without person-wide over-invalidation",
          "Actual production interest sets for both currently bound queries, constructed from coherent view models rather than synthetic subsets",
          "Binding loader-count proof for same-Person different-club isolation, selected-club current-Person refresh and differing same-club effects for dashboard versus detail",
          "A complete two-query audit against all other producer families so no affected production query is silently omitted",
          "Exact collection, relationship, identity and authorization invalidations for valid complete events",
          "Only evidenced broader scopes, including MessageSent club-conversation scope, RolePermission club fan-out and ConversationGroupAccess conversation-wide authorization",
          "Stable lifecycle-visible contract violations for recognized malformed or unsupported projector/event pairings",
          "Corrected Membership and query-interest migration-matrix rows and fresh independent review"
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
          },
          {
            "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
            "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
            "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          },
          {
            "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
            "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
            "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          },
          {
            "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
            "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
            "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          },
          {
            "base_sha": "e881b12146435be4021c60cae3c5bab1647f6df7",
            "head_sha": "e030351a2db3f21ec29fc6d31bf8392a8db5946a",
            "packet_id": "task-008a-e881b12-isolation-vocabulary-revision-5",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          },
          {
            "base_sha": "8cb6cc97504c555deba5d5f018e51d99e3429f3b",
            "head_sha": "8043946a13599b5d6ba8e6af81dc9705794f3cf5",
            "packet_id": "task-008a-8cb6cc9-full-projector-isolation-revision-6",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          }
        ]
      },
      {
        "task_id": "task-008b",
        "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "status": "pending",
        "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
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
        "status": "pending",
        "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
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
        "status": "pending",
        "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
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
        "status": "pending",
        "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
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
        "status": "pending",
        "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
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
        "status": "pending",
        "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
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
        "status": "pending",
        "origin": "Approved implementation step 6.",
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
        "status": "pending",
        "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
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
      },
      {
        "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
        "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
        "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
        "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
        "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
        "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
        "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "e881b12146435be4021c60cae3c5bab1647f6df7",
        "head_sha": "e030351a2db3f21ec29fc6d31bf8392a8db5946a",
        "packet_id": "task-008a-e881b12-isolation-vocabulary-revision-5",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "8cb6cc97504c555deba5d5f018e51d99e3429f3b",
        "head_sha": "8043946a13599b5d6ba8e6af81dc9705794f3cf5",
        "packet_id": "task-008a-8cb6cc9-full-projector-isolation-revision-6",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      }
    ],
    "coverage_map": [
      {
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction and accepted consumer adoption.",
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
          "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
        ],
        "pending_task_ids": []
      },
      {
        "scope": "Complete task 008A by repairing selected-club Membership authority isolation in both actual bound queries, preserving person-wide producer support for future all-clubs consumers, auditing both complete production interest sets against all producer families, reconciling the migration matrix and obtaining fresh independent review.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008a"
        ]
      },
      {
        "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008b",
          "task-008c",
          "task-008d",
          "task-008e",
          "task-008f"
        ]
      },
      {
        "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009"
        ]
      },
      {
        "scope": "Complete production package, Docker release and repository quality-gate integration.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-010"
        ]
      },
      {
        "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011"
        ]
      }
    ],
    "planner_note": "The clean binding checkpoint is c0227b578a9196b34098aba0f76c6e163c155237. Tasks 001, 003, 004, 005, 006, 006A, 007A and 007B remain preserved exactly as accepted. Task 008A remains the first unchecked line with unchanged identity and wording; no todo split or edit is needed. The prior blocked/escalated run and revision-6 reviewer verdict remain provenance, and all six review-revise candidate origins are retained. Matt’s bounded BB delegation authorizes one exact technical revision from this checkpoint but does not accept 008A, approve publication or reopen Slack coordination. Current code confirms the defect: Membership emits `{:person_clubs, person_id}`, while both real bound queries register that person-wide key, so the same Person changing membership in another club matches a selected-club query. The next packet adds a distinct `{:person_club, club_id, person_id}` producer key while retaining `{:person_clubs, person_id}` for true all-clubs consumers, replaces only the two bound queries’ person-wide interests, reconciles the matrix, and requires Binding proof built from actual `MemberDashboardQuery.interests/1` and `MemberMessageDetailQuery.interests/1` results. To prevent another synthetic blind spot, it also requires complete production-interest-set assertions and an explicit two-query audit across every recognized source family, retaining deliberate MessageSent, RolePermission and ConversationGroupAccess breadth. This is coherent within one bounded revision touching only the adapter, both query modules, their focused tests and the migration matrix. The approved acceptance scenario is already accepted and green, so scenario_focus is null; the deterministic full gate remains later work."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c0227b578a9196b34098aba0f76c6e163c155237",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-c0227b5-selected-club-authority-revision-7",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c0227b578a9196b34098aba0f76c6e163c155237",
    "outcome": "Complete the bounded task-008a repair so Membership publications support both exact selected-club authority and true person-wide all-clubs consumers, while the real dashboard and conversation-detail query interest sets isolate same-Person changes in other clubs and retain every justified same-club and intentionally broad refresh.",
    "scope": [
      "Change the Membership producer mapping in `MembaReadModelSource` so every valid current or recovered legacy Membership change emits all four justified keys: `{:club_members, club_id}`, `{:membership, membership_id}`, `{:person_club, club_id, person_id}`, and `{:person_clubs, person_id}`.",
      "Retain `{:person_clubs, person_id}` as a producer invalidation for future or pending consumers that genuinely display all active clubs; do not remove or repurpose it to solve the current isolation bug.",
      "Replace `{:person_clubs, current_person_id}` with `{:person_club, selected_club_id, current_person_id}` in `MemberDashboardQuery.interests/1`, keeping its current exact membership, selected-club member collection and every other justified displayed or authorization interest.",
      "Replace `{:person_clubs, person_id}` with `{:person_club, club_id, person_id}` in `MemberMessageDetailQuery.interests/1`, keeping its current exact membership, exact group participation, conversation/access/follow, represented Person, message and delivery interests.",
      "Strengthen the query tests to compare each coherent fixture view model’s actual `interests/1` result as a complete set, including the selected-club authority key and explicitly excluding the person-wide key from both bound queries; do not rely only on positive subset assertions.",
      "In Binding tests, construct coherent dashboard and detail view models and call the real production `MemberDashboardQuery.interests/1` and `MemberMessageDetailQuery.interests/1`; register those complete returned lists with Binding without deleting broad or inconvenient interests by hand.",
      "For both actual query interest lists, prove a Membership event for the current Person in another club causes zero rereads after the initial load, leaving the loader count at one.",
      "For both actual query interest lists, prove a Membership event for the current Person in the selected club causes exactly one reread, advancing the loader count from one to two. Use a different membership ID where useful so the detail proof exercises selected-club authority rather than passing only through its preexisting exact membership identity.",
      "Using those same actual query interests, prove an unrelated Person’s Membership change in the selected club refreshes dashboard exactly once through its displayed `club_members` collection but causes zero rereads for conversation detail, which does not display the club-member collection.",
      "Preserve exact malformed Membership behavior and legacy retained-row recovery, and update exact invalidation-set tests for current and legacy add/remove events to require both `person_club` and `person_clubs` keys.",
      "Audit the complete actual dashboard and detail interest sets against representative valid notifications from all eleven recognized projector families. Record for each query which invalidation intersects and whether refresh or ignore is expected; add focused regression assertions wherever the production interests expose an untested match or isolation boundary rather than silently omitting that query.",
      "Keep intentional breadth and regression proof: MessageSent retains club-conversation invalidation, ClubRolePermissionGranted retains same-club permission fan-out, and ConversationGroupAccess retains conversation-wide authorization invalidation.",
      "Reconcile the Membership producer row, query-to-interest coverage and affected dashboard/detail text in `migration-matrix.md`, distinguishing selected-club authority `person_club` from true all-active-clubs collection `person_clubs` and documenting each current consumer accurately.",
      "Leave task 008A unchecked and return a complete candidate for fresh independent review."
    ],
    "scope_exclusions": [
      "Do not treat this delegation as task-008a acceptance, publication approval or permission to contact Slack.",
      "Do not modify projector implementations, event structs, projection schemas, aggregates, commands, read APIs or `Memba.ReadModelChanges` publishing.",
      "Do not modify `packages/live_query/**` or weaken exact tuple equality in the frozen generic Source or Binding contract.",
      "Do not remove the person-wide `{:person_clubs, person_id}` Membership invalidation; pending settings and other true all-clubs consumers may require it.",
      "Do not remove dashboard’s `{:club_members, club_id}` collection interest merely to make unrelated same-club member changes appear isolated; those changes legitimately alter its displayed rows and counts.",
      "Do not add `club_members` or another broad Membership interest to conversation detail.",
      "Do not remove MessageSent club-conversation invalidation, RolePermission club-permission fan-out or ConversationGroupAccess conversation-wide authorization invalidation.",
      "Do not introduce wildcards, broad family fallbacks, malformed-event recovery beyond the already evidenced legacy Membership row lookup, or synthetic partial event maps as valid variants.",
      "Do not change LiveViews, routes, templates, forms, navigation, acceptance features, ADRs, the approved plan or the todo.",
      "Do not implement tasks 008B through 011 or migrate another LiveView.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic iteration gate owns full validation.",
      "Do not mark task 008A complete; fresh independent review owns acceptance."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires affected-query-only refresh, fresh authorization, exact collection and identity scope where available, unrelated-club isolation, and broader invalidation only for evidenced valid event shapes."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation and remains responsible for actual projector-family auditing, exact scoped matching, corrected matrix evidence and fresh independent review."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint requires preserving all six task-008a review-revise candidate origins, including revision 6. The packet source baseline is current HEAD c0227b578a9196b34098aba0f76c6e163c155237, not the baseline predecessor."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "Revision 6 reported 41 adapter/Binding tests and 8 query tests green, but its same-Person isolation proof used a synthetic interest subset and therefore did not exercise the real queries’ person-wide key."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent revision-6 review identified the real defect: Membership emits person_clubs and both bound queries register it, so a current Person’s different-club Membership change rereads selected-club queries. Review requires a club-scoped current-authority key and Binding proof from actual query interests."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The current Membership row describes one person-wide active-clubs collection for dashboard, settings and detail. It must distinguish exact selected-club authority from genuine all-active-clubs display dependencies and update the query coverage rows accordingly."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "Interests and invalidations are opaque exact values to the generic package; the correction belongs in the app-owned producer vocabulary and consumer interest sets, not generic matching."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Projectors publish only after their projection transaction commits, and the application notification includes the projector, actual source event and committed changes."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Relevant changes trigger fresh authorized reads, while imprecise interests add unnecessary database work; Memba-specific mapping remains app-owned."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Current `membership_invalidations/3` emits club_members, membership and person_clubs. It has club_id and person_id available and must add exact person_club while retaining person_clubs. The adapter recognizes eleven projector families and uses strict matching."
      },
      {
        "path": "web/lib/memba/membership/projectors/membership.ex",
        "facts": "Current Membership add/remove events and recoverable legacy removal scope identify club, membership and Person, supporting both exact selected-club authority and person-wide active-club invalidations."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The real dashboard interest list currently contains person_clubs plus club_members, exact current membership, selected group authorization, represented members, roles, conversations and other displayed collection interests. Only person_clubs should become selected-club person_club."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "The real detail interest list currently contains person_clubs plus exact membership, group participation, conversation/access/follow, represented Person, message and delivery keys. It should use selected-club person_club and remain free of club_members."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "The existing same-Person/different-club Membership test registers only person and club_members, omitting both real queries’ person_clubs key. The current detail helper calls production interests, but no equivalent production dashboard helper or complete two-query family audit exists."
      },
      {
        "path": "web/test/memba_web/member_dashboard_query_test.exs",
        "facts": "The coherent dashboard fixture currently checks interests mostly by membership in subsets and does not assert a complete set or explicitly expose the person_clubs isolation defect."
      },
      {
        "path": "web/test/memba_web/member_message_detail_query_test.exs",
        "facts": "The coherent detail fixture positively asserts person_clubs and checks other interests by subset membership. It must assert the complete production set with selected-club person_club instead."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Process tests should use deterministic counters or messages without sleeps; the existing supervised Agent-backed Binding loader counter is appropriate for exact reread counts."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The sole approved acceptance scenario is already green with its prediction matched, so this bounded technical revision has no appropriate new scenario-first run."
      }
    ],
    "constraints": [
      "Preserve the prior blocked/escalated run and revision-6 verdict as provenance. This packet is an explicitly delegated bounded repair, not a reset, renamed task, acceptance decision or publication approval.",
      "Limit implementation changes to `MembaReadModelSource`, `MemberDashboardQuery`, `MemberMessageDetailQuery`, their focused tests and the affected `migration-matrix.md` sections.",
      "Use actual event structs and complete committed-change envelopes in adapter tests; do not introduce synthetic partial maps as valid event variants.",
      "Use coherent fixture view models or real loaders to obtain interests by calling both production `interests/1` functions. Register those returned lists unchanged with Binding; do not hand-pick subsets for isolation tests.",
      "Assert complete query interests as sets so unexpected broad keys and missing exact keys both fail. Preserve justified dynamic represented identities, collection scopes and intentional broad interests.",
      "For the selected-club current-Person Membership proof, avoid an assertion that can pass solely through an unchanged exact membership ID when the purpose is to establish the new person_club key.",
      "Audit all eleven source families against both actual query interest sets. An expected ignore must be justified by absent query dependency; an expected refresh must identify the exact intersecting key. Do not silently omit either query from a family because it is inconvenient.",
      "Before the first post-test-edit adapter-suite run, record the expected current diagnostics: exact Membership invalidation sets lack `{:person_club, \"club-1\", \"person-current\"}`, and Binding with either real query interest list rereads on a same-Person `club-2` Membership event because `{:person_clubs, \"person-current\"}` intersects.",
      "Before the first post-test-edit query-suite run, record that complete-set assertions are expected to show unexpected `{:person_clubs, \"person-current\"}` and missing `{:person_club, \"club-1\", \"person-current\"}`.",
      "Predict both focused test commands will be green after the single production correction. If another family’s actual production interests reveal a surprising match or omission, report and diagnose it rather than deleting that interest or weakening the complete-set audit.",
      "Keep strict equality in `MembaReadModelSource.matches?/2`; fix producer invalidations and consumer interests.",
      "Retain current complete-envelope gating, malformed recognized-event exceptions, legacy retained-row recovery, validated no-op behavior and exact mappings from revision 6.",
      "Prepare one complete candidate for fresh independent review. If the two-query, eleven-family audit reveals a materially larger policy or migration decision, stop and return a replan or human-blocked result without silently narrowing scope."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and summarize the producer, query-interest, proof or matrix correction in each.",
      "Show the exact Membership invalidation set for current add/remove and recovered legacy events, including club_members, membership, person_club and person_clubs.",
      "Show the complete actual interest set for the coherent dashboard fixture and the complete actual interest set for the coherent conversation-detail fixture; confirm each contains selected-club person_club and excludes person_clubs.",
      "Show Binding loader counts for both real query interest lists: same Person in another club remains at one load, selected-club current Person advances from one to two, and an unrelated same-club member advances dashboard from one to two while detail remains at one.",
      "Explain which exact key causes each relevant Membership refresh and why the different-club event intersects neither actual query.",
      "Provide an eleven-family by two-query audit covering Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery, naming the actual intersecting key or justified ignore for dashboard and detail.",
      "Confirm MessageSent club-conversation, RolePermission club-permission and ConversationGroupAccess conversation-wide invalidations remain present and behave as intended with the actual production interest sets.",
      "Confirm complete-envelope gating, strict equality, malformed recognized-event exceptions, legacy retained-row recovery, Person/Group/GroupMembership mappings, exact follow behavior, both delivery contributors and validated no-op behavior remain green.",
      "Report the recorded pre-run diagnostic predictions and whether the initial focused red results matched the missing person_club, unexpected person_clubs and loader-count expectations.",
      "Report successful exit status, test count and failure count for both focused test commands after implementation, plus format and diff-check results.",
      "Confirm no package, LiveView, route, template, form, projector, event, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed.",
      "Confirm task 008A remains unchecked and that the candidate is returned for fresh independent review without publication approval."
    ],
    "candidate_origins": [
      {
        "base_sha": "0b2466fc574c2110b09a5019d8c280658d035cd0",
        "head_sha": "2a0fe98dbfb9d10a23d045e8e517c45d6b02f89b",
        "packet_id": "task-008a-0b2466f-adapter-matrix-1",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors."
      },
      {
        "base_sha": "5a0be69826405522dbbc727b73e11cb5eac89784",
        "head_sha": "b9987229e5bdcd20e7e0314a32d616766d88f16c",
        "packet_id": "task-008a-5a0be69-projector-contract-revision-2",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "59e50fa26a52a8d3376a356546c3ba9309d79681",
        "head_sha": "c1af0f426158cc35e0e5c10c866a3d010ed9166a",
        "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "0c2dbfb5cb423a4f20f8766e2826f156a3655c60",
        "head_sha": "8c4a977c448be4962a0fa520ab81f15319d840a3",
        "packet_id": "task-008a-0c2dbfb-noop-identity-revision-4",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "e881b12146435be4021c60cae3c5bab1647f6df7",
        "head_sha": "e030351a2db3f21ec29fc6d31bf8392a8db5946a",
        "packet_id": "task-008a-e881b12-isolation-vocabulary-revision-5",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "8cb6cc97504c555deba5d5f018e51d99e3429f3b",
        "head_sha": "8043946a13599b5d6ba8e6af81dc9705794f3cf5",
        "packet_id": "task-008a-8cb6cc9-full-projector-isolation-revision-6",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      }
    ],
    "scenario_focus": null
  }
}