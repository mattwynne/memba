{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
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
        "origin": "Adapter-completion portion of approved implementation step 4, corrected through review to distinguish changed projection dependencies, exact relationship scopes, valid no-op publications and malformed recognized notifications.",
        "status": "prepared",
        "coverage": [
          "All actual event families published by the eleven in-scope projectors",
          "Exact collection, relationship, identity and authorization invalidations for valid complete events",
          "No Person invalidation from Membership or GroupMembership relationship changes",
          "No conversation-wide invalidation from member-specific ConversationFollow changes",
          "No unchanged Group identity invalidation from ConversationGroupAccess changes",
          "No producerless generic fallback interests in the accepted dashboard or conversation-detail consumers",
          "Only evidenced broader scopes, including MessageSent club-conversation scope and role/permission fan-out",
          "Legacy MemberRemoved scope recovery from the retained membership row",
          "Stable lifecycle-visible contract violations for recognized malformed or unsupported projector/event pairings",
          "Refresh-count proof for same-conversation/different-member and same-Person/different-club isolation",
          "Corrected migration-matrix rows and fresh independent review"
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
      }
    ],
    "coverage_map": [
      {
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction and accepted consumer adoption.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
          "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
        ]
      },
      {
        "scope": "Correct and prove the app-owned notification adapter and accepted consumers use only changed projection dependencies, exact relationship scopes and evidenced broader invalidations, with no inert fallback vocabulary.",
        "pending_task_ids": [
          "task-008a"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing transient LiveView state.",
        "pending_task_ids": [
          "task-008b",
          "task-008c",
          "task-008d",
          "task-008e",
          "task-008f"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence.",
        "pending_task_ids": [
          "task-009"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Complete production package, Docker release and repository quality-gate integration.",
        "pending_task_ids": [
          "task-010"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation.",
        "pending_task_ids": [
          "task-011"
        ],
        "accepted_task_lines": []
      }
    ],
    "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and keeps the same task identity, todo wording and revision lineage; all four unaccepted candidate origins required by the baseline are retained. The latest candidate correctly closes the malformed recognized no-op gap and reports 30 focused adapter tests passing, but independent review found that relationship notifications still emit identity invalidations for projections they did not change: ConversationFollow emits a conversation identity, and Membership and GroupMembership emit a Person identity. Direct inspection also confirms ConversationGroupAccess emits an unchanged Group identity, both accepted queries register producerless generic fallback interests, and conversation detail retains two producerless broad follow interests. This bounded revision aligns those mappings and interests with the corrected matrix and adds loader-count proof that unrelated queries are not reread. No todo edit or semantic split is needed. The only approved acceptance scenario is already accepted and green; this adapter/query-vocabulary recovery has no appropriate new agreed scenario, so scenario_focus is null and focused technical proof is used."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-e881b12-isolation-vocabulary-revision-5",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "e881b12146435be4021c60cae3c5bab1647f6df7",
    "outcome": "Align committed-read-model invalidations and accepted consumer interests with actual changed projection dependencies so member-specific or cross-club relationship changes do not reread unrelated queries, while removing producerless fallback vocabulary and retaining every required exact, collection, authorization and evidenced broad scope.",
    "scope": [
      "Remove `{:conversation, conversation_id}` from explicit and auto-following ConversationFollow invalidations; retain only the exact `{:conversation_follow, conversation_id, member_id}` relationship key, while preserving complete false-auto-follow `:ignore` behavior and required-identity validation.",
      "Remove `{:person, person_id}` from Membership invalidations because membership events do not change the Person projection; retain `{:club_members, club_id}`, `{:membership, membership_id}` and `{:person_clubs, person_id}` for the changed collection, exact relationship and active-club authority dependency.",
      "Remove `{:person, person_id}` from GroupMembership invalidations; retain `{:group_members, group_id}`, `{:person_groups, club_id, person_id}` and `{:group_participation, club_id, group_id, person_id}`.",
      "Remove the unchanged `{:group, group_id}` identity from ConversationGroupAccess invalidations while retaining the group-conversation collection, exact access relationship and conversation-wide authorization invalidation.",
      "Remove the dashboard and conversation-detail `@fallback_families`, `fallback_interests/1` helpers and all `{:fallback, ...}` interests because the corrected source emits only concrete keys, `:ignore`, or a visible contract violation.",
      "Remove conversation detail's producerless `{:conversation_follows, conversation_id}` and `{:member_conversation_follows, person_id}` interests while retaining its exact current-member follow interest.",
      "Correct only the affected Membership, GroupMembership, ConversationFollow and ConversationGroupAccess rows of the migration matrix so documented logical interests match the actual changed projections and precise adapter output.",
      "Update exact invalidation-set and query-interest tests, and add Binding-level loader-count tests proving a same-conversation/different-member follow change and same-Person/different-club Membership or GroupMembership changes do not reread an unrelated registration.",
      "Include a loader-count isolation case for ConversationGroupAccess on an unselected represented group, while proving a relevant exact access or conversation-wide authorization change still refreshes where required.",
      "Preserve all previously reviewed envelope validation, eleven-family dispatch, valid no-op handling, retained-row legacy MemberRemoved recovery, contract-violation lifecycle behavior, MessageSent club-conversation scope, role/permission fan-out and independent delivery-projector convergence."
    ],
    "scope_exclusions": [
      "Do not modify `packages/live_query/**` or broaden the frozen generic Query, Source or Binding API.",
      "Do not change LiveViews, routes, templates, components, forms, navigation, commands, event structs, projectors, projection schemas, publishers or read APIs.",
      "Do not remove `{:conversation, conversation_id}` from ConversationGroupAccess; that key preserves conversation-wide fresh authorization when any access relationship for the conversation changes.",
      "Do not alter role/permission mappings, MessageSent's evidenced club-conversation collection, delivery mappings, legacy MemberRemoved retained-row recovery, complete-envelope gating or stable contract-violation behavior.",
      "Do not introduce new broad, global, family fallback, projection-row lookup or changes-map recovery behavior.",
      "Do not implement tasks 008B through 011 or migrate another LiveView.",
      "Do not edit the approved plan, todo, ADRs, extraction contract or acceptance feature; migration-matrix edits are limited to reconciling the four affected adapter rows.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite; the deterministic iteration gate owns full validation.",
      "Do not mark task 008A complete; fresh independent review owns acceptance."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires refreshing only affected query results, exact collection and relationship scopes where available, evidenced broader invalidation only for valid events lacking exact scope, and no silent fallback for malformed recognized notifications."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation and owns exact scoped matching, unrelated-projector isolation, actual projector/event-family auditing, corrected matrix fallbacks, focused proof and fresh independent review."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The binding checkpoint is current HEAD and requires preservation of all four task-008a review-revise candidate origins, including the latest no-op identity revision."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest worker changed only the adapter and its focused tests, reported 30 adapter tests passing, and correctly moved required-field validation ahead of false-auto-follow and EmailDeliveryOpened no-op decisions."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted the no-op identity correction but requires removal of conversation-wide follow and cross-scope Person invalidations, loader-count isolation proof, and completion of the consumer fallback audit."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The current adapter rows still describe Person identity for Membership and GroupMembership, conversation identity for ConversationFollow, and Group identity for ConversationGroupAccess; those claims must be reconciled with the projections actually changed."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen package contract uses opaque exact source matching, refreshes only matching registrations, and atomically replaces a query's result and interests; this revision changes only app-owned vocabulary and proof."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Projectors publish their source event and committed changes after projection transactions, providing the boundary from which the app adapter must derive precise affected read-model keys."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture says a relevant committed change triggers a fresh authorized read, while imprecise invalidation creates unnecessary database work; Memba mapping remains in the app."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Current Membership and GroupMembership mappings emit `{:person, person_id}`, current ConversationFollow mappings emit both exact follow and conversation identity, and ConversationGroupAccess emits an unchanged Group identity. Matching itself is strict tuple equality and the source emits no generic fallback tuple."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "The focused suite currently asserts the over-broad invalidation sets and already contains Binding/query helpers suitable for direct loader-count proof without relying on unchanged rendered HTML."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The dashboard registers concrete collection, represented-identity and authorization interests but also appends sixteen producerless global and club-scoped fallback interests from eight fallback families."
      },
      {
        "path": "web/test/memba_web/member_dashboard_query_test.exs",
        "facts": "The dashboard query test enumerates required concrete interests and can assert that no `{:fallback, ...}` interest remains after cleanup."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "Conversation detail registers the required exact current-member follow key, but also appends sixteen generic fallback interests and two broad follow interests for which the source has no producer."
      },
      {
        "path": "web/test/memba_web/member_message_detail_query_test.exs",
        "facts": "The detail query test currently positively asserts `{:fallback, :delivery}` and both producerless broad follow interests, so it must be corrected while retaining exact conversation, access, author, follow and delivery coverage."
      },
      {
        "path": "web/lib/memba/membership/projectors/group_membership.ex",
        "facts": "GroupMembership events update only the group-membership projection relationship; they do not modify a Person projection, supporting removal of the Person identity invalidation."
      },
      {
        "path": "web/lib/memba/messaging/projectors/conversation_follow.ex",
        "facts": "ConversationFollow events and auto-following MessageSent update one conversation/member follow row, while false-auto-follow MessageSent is a projector no-op; the changed dependency is the exact follow relationship."
      },
      {
        "path": "web/lib/memba/messaging/projectors/conversation_group_access.ex",
        "facts": "Conversation access events upsert or delete one conversation/group relationship and do not modify the Group projection; group-collection, exact-access and conversation-wide authorization keys remain sufficient."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused process tests must avoid sleeps and process-liveness polling; direct loader counters or messages and deterministic synchronization should prove absence of an unrelated reread."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The iteration's sole approved acceptance scenario is already green with its prediction matched, so this technical recovery must not fabricate another scenario-first cycle."
      }
    ],
    "constraints": [
      "Limit changes to the app-owned adapter, the two accepted query modules, their three focused test files, and the four affected rows in `migration-matrix.md`; report an unavoidable conflict before expanding scope.",
      "Treat projector implementation and actual query reads as ground truth: a relationship event must not emit an identity key for an unchanged projection merely because a query also represents that identity.",
      "Keep exact tuple equality in `MembaReadModelSource.matches?/2`; solve isolation by correcting emitted invalidations and consumer interests, not by adding asymmetric wildcard matching.",
      "Preserve `{:person_clubs, person_id}` for Membership because active-club authority genuinely changes, and preserve club/group-scoped participation keys for GroupMembership.",
      "Preserve the exact current-member follow key and remove only conversation-wide follow invalidation; another member's follow state must not reread the open member's detail or a dashboard representing the same conversation.",
      "For ConversationGroupAccess, preserve `{:group_conversations, group_id}`, exact `{:conversation_access, group_id, conversation_id}` and `{:conversation, conversation_id}`; remove only the unchanged Group identity.",
      "Remove producerless fallback and broad-follow interests rather than inventing source emissions to justify them.",
      "Add read-count evidence at the Binding boundary: the new tests must distinguish no reread from a reread that happens to render unchanged output.",
      "Before the initial focused red run, record a concrete expected diagnostic showing the loader count increased from one to two for an unrelated notification or that an unexpected broad/fallback tuple remained; after the correction, predict the focused commands will be green.",
      "Use actual event structs and complete committed-change envelopes in adapter tests; do not reintroduce synthetic partial maps as valid variants.",
      "Prepare evidence for fresh independent review and leave the todo line unchecked."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"
    ],
    "completion_evidence_required": [
      "List every changed path and summarize the precise invalidation or interest removed from each.",
      "Report the initial focused-red diagnostic and confirm it matched the predicted extra loader invocation or unexpected tuple.",
      "Report successful exit status, test count and failure count for both focused validation commands after implementation.",
      "Show exact invalidation sets for Membership, GroupMembership, ConversationFollow and ConversationGroupAccess after the correction.",
      "Show loader-count evidence that same-conversation/different-member follow changes and same-Person/different-club Membership and GroupMembership changes leave the unrelated query at its initial load count.",
      "Show loader-count evidence that access changes for an unselected represented group do not reread through an unchanged Group identity, while relevant access or conversation authorization invalidation still refreshes.",
      "Show that both accepted queries contain no `{:fallback, ...}` interests and that conversation detail contains only the exact follow relationship it can receive from the source.",
      "Confirm the migration-matrix rows now match actual emitted keys and distinguish changed projection identities from relationship and collection dependencies.",
      "Confirm false-auto-follow MessageSent and EmailDeliveryOpened remain valid no-ops after complete identity validation, and malformed recognized notifications retain their stable lifecycle-visible exception behavior.",
      "Confirm all other previously reviewed adapter behavior remains green, including complete-envelope gating, eleven-family dispatch, MessageSent's club-conversation scope, retained-row legacy recovery, role/permission fan-out and both delivery projectors.",
      "Report `bin/mix format --check-formatted` and `git diff --check` results in the worker summary without running an unscoped repository suite.",
      "Confirm no package, LiveView, route, template, form, event, projector, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed."
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
      }
    ],
    "scenario_focus": null
  }
}