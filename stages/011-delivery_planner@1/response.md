{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5fe939cbee78cce9fe140e16d13c2601d77bc46d",
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
        "origin": "Adapter-completion portion of approved implementation step 4, corrected through eight independent review-revise candidates and Matt's explicitly delegated bounded revision-9 test-proof repair.",
        "status": "prepared",
        "coverage": [
          "All actual event families published by the eleven source-recognized projectors",
          "Exact Membership invalidations, selected-club isolation and retained-MembershipProjection-only legacy recovery already implemented and passing",
          "A dashboard message row produced by the public MemberDashboardPresentation.present_message_rows/2 boundary from a coherent production-shaped conversation input",
          "Canonical root message and conversation identity, equal sender and originator identities, and a latest replier represented among participants",
          "A reply count coherent with the two distinct non-originator participant identities used by the fixture",
          "An exact dashboard-interest set of 30 interests that excludes the impossible person-originator identity while retaining the actual author, latest replier and participant identities",
          "Unchanged complete conversation-detail interests, eleven-projector-family intersections and positive/negative Binding loader-count proofs",
          "Preservation of the corrected Membership migration-matrix rule and all production adapter/query behavior",
          "Fresh independent review with task 008A remaining unchecked"
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
          },
          {
            "base_sha": "c0227b578a9196b34098aba0f76c6e163c155237",
            "head_sha": "3da496a01ae312d0a19e6b70c28f96cd2308aafe",
            "packet_id": "task-008a-c0227b5-selected-club-authority-revision-7",
            "reason": "review_revise",
            "task_id": "task-008a",
            "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
          },
          {
            "base_sha": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
            "head_sha": "d8ab20fd26aee73ce1bee85c7aa965175528ee7b",
            "packet_id": "task-008a-3971e31-coherent-audit-revision-8",
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
      },
      {
        "base_sha": "c0227b578a9196b34098aba0f76c6e163c155237",
        "head_sha": "3da496a01ae312d0a19e6b70c28f96cd2308aafe",
        "packet_id": "task-008a-c0227b5-selected-club-authority-revision-7",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
        "head_sha": "d8ab20fd26aee73ce1bee85c7aa965175528ee7b",
        "packet_id": "task-008a-3971e31-coherent-audit-revision-8",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      }
    ],
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
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction and accepted consumer adoption."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008a"
        ],
        "scope": "Complete task 008A by replacing the impossible hand-authored dashboard message row with a row produced by the public production presenter, asserting sender/originator, participant/latest-replier and reply-count coherence, updating the exact interest set from 31 to 30, preserving all established adapter and matrix behavior, rerunning focused proof and obtaining fresh independent review."
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
    "planner_note": "The binding checkpoint is current HEAD 5fe939cbee78cce9fe140e16d13c2601d77bc46d. Tasks 001, 003, 004, 005, 006, 006A, 007A and 007B remain preserved exactly as accepted. Task 008A remains the first unchecked line with unchanged identity and wording, so todo.md required no edit. The prior blocked run remains blocked, and revision 8 is preserved as the eighth review-revise candidate and independent non-acceptance verdict. Matt explicitly delegated this bounded BB repair without Slack contact or publication. Inspection confirms the remaining defect is test-proof-only: dashboard_result/0 hand-authors an impossible row with sender_id person-author and originator_id person-originator, and latest_replier_id person-replier absent from participants. Production MemberDashboardPresentation.present_message_rows/2 derives sender_id and originator_id from conversation.sender_id, while Messaging.conversations_query/1 includes every distinct non-originator reply sender in participant_ids. The prepared revision therefore changes only web/test/memba_web/live_query/memba_read_model_source_test.exs, constructs message_rows through the public presenter from a coherent canonical-root conversation, adds explicit relationship assertions, drops only the impossible person-originator interest and updates the exact cardinality from 31 to 30. Production adapter/query/presenter code, selected-club invalidations, the corrected Membership matrix, complete detail interests, eleven-family semantics and Binding isolation proof stay unchanged. The sole approved acceptance scenario is already accepted and green, so this technical test repair has no appropriate scenario-first run. Task 008A remains unchecked for fresh independent review; the final dev check remains task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5fe939cbee78cce9fe140e16d13c2601d77bc46d",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-5fe939c-presenter-coherence-revision-9",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5fe939cbee78cce9fe140e16d13c2601d77bc46d",
    "outcome": "Repair only the remaining false dashboard-interest proof by deriving its message row through the public production presenter from a coherent conversation, explicitly proving its identity and participant relationships, and retaining every previously passing adapter, matrix, family-audit and isolation behavior for fresh independent review.",
    "scope": [
      "In `web/test/memba_web/live_query/memba_read_model_source_test.exs`, alias and call public `MembaWeb.MemberDashboardPresentation.present_message_rows/2` from `dashboard_result/0` instead of hand-authoring the dashboard `message_rows` presentation result.",
      "Supply one coherent conversation input whose `message_id` and `conversation_id` are the canonical root `conversation-1`, whose `sender_id` is `person-author`, and whose subject, body and `inserted_at` fields satisfy the presenter's public input shape; `inserted_at` may be nil.",
      "Give the conversation `reply_count: 2`, `latest_replier_id: \"person-replier\"`, `latest_replier_name`, and `participant_ids` containing both `person-participant` and `person-replier`. Supply a names map for the author, latest replier and other participant so the presenter constructs realistic participant rows.",
      "Keep `audited_reply_event/0` linked to the same canonical root through both `conversation_id` and `reply_to_message_id`.",
      "Extend the existing coherent-dashboard test with explicit assertions that the presented row has `originator_id == sender_id`, that the distinct latest replier appears among rendered participant IDs, and that this fixture's reply count equals its two rendered participant identities.",
      "Continue deriving the complete dashboard interests exclusively through `MemberDashboardQuery.interests/1` from that presenter-produced result.",
      "Update `expected_dashboard_interests/0` to remove only `{:person, \"person-originator\"}`. Retain `{:person, \"person-author\"}`, `{:person, \"person-replier\"}` and `{:person, \"person-participant\"}`, and prove the exact dashboard cardinality is 30.",
      "Rerun the existing complete dashboard/detail interest tests, all eleven projector-family intersections, and the positive and negative Membership Binding loader-count tests without changing their semantics.",
      "Leave task 008A unchecked and return this single-file test-proof candidate for fresh independent review."
    ],
    "scope_exclusions": [
      "Do not modify application code, including `MembaReadModelSource`, `MemberDashboardQuery`, `MemberDashboardPresentation`, `Messaging`, `MemberMessageDetailQuery`, projectors, events, projections, publishers, packages or LiveViews.",
      "Do not modify `docs/iterations/067-live-projection-queries/migration-matrix.md`; its retained-MembershipProjection-only correction already passes review and must remain unchanged.",
      "Do not change the selected-club Membership invalidations, legacy recovery behavior, exact matching, complete-envelope gating, malformed recognized-event exceptions, validated no-ops, broad valid Message scope, follow behavior or either delivery contributor.",
      "Do not reduce the production interest lists before Binding or family-audit assertions, and do not weaken exact MapSet or cardinality assertions.",
      "Do not remove the actual author, latest replier or participant Person interests to make the count pass.",
      "Do not alter the coherent conversation-detail fixture, its 13-interest expectation or its represented root author proof.",
      "Do not edit query tests, presentation tests, messaging projection tests, the approved plan, todo, ADRs, acceptance features or other documentation.",
      "Do not implement tasks 008B through 011 or migrate another LiveView.",
      "Do not contact Slack, impersonate Matt, approve publication, accept task 008A or reinterpret revision 8 as accepted evidence.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and final task 011 own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires one coherent dashboard result, complete represented-record interests, affected-query-only refresh, actual projector-family proof and a fresh independent review. It assigns the final full dev check to the iteration's final validation work."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation. It remains unchecked and retains its adapter-family, exact matching, malformed Membership, corrected-matrix and independent-review requirements."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The binding checkpoint for this visit is HEAD 5fe939cbee78cce9fe140e16d13c2601d77bc46d. All eight task-008a review-revise candidate origins, including revision 8, must remain attached as unaccepted provenance."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The independent revision-8 decision is revise, not acceptance. Its sole remaining gap is the impossible dashboard row: sender and originator differ, and the latest replier is absent from participants. It requests production presenter construction, explicit coherence assertions and an updated exact set/count."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "Revision 8 recorded 46 adapter/Binding tests and 8 supporting query tests passing. It established the corrected Membership matrix, canonical root linkage, 13 detail interests, eleven-family intersections and expected Binding loader counts; preserve those results while repairing the false dashboard fixture."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "`dashboard_result/0` currently hand-authors sender_id `person-author`, originator_id `person-originator`, latest_replier_id `person-replier`, and participants containing only `person-participant`. The resulting expected list has 31 interests including an impossible extra `person-originator`; this helper feeds the complete-interest, eleven-family and Binding isolation tests."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_presentation.ex",
        "facts": "Public `present_message_rows/2` derives both `sender_id` and `originator_id` from `conversation.sender_id`, copies `reply_count` and `latest_replier_id`, and renders participant rows from `participant_ids` and the supplied names map. It accepts nil `inserted_at` and falls back safely for missing names."
      },
      {
        "path": "web/lib/memba/messaging.ex",
        "facts": "`conversations_query/1` selects root message and conversation identities from the canonical root, counts every projected reply, selects the latest reply sender, and builds `participant_ids` from every distinct non-originator reply sender. Thus a distinct latest replier must occur among participant IDs."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "`interests/1` reads sender, originator, latest replier and rendered participant IDs from each presented message row, deduplicates them, and creates exact Person interests. A production-valid row therefore yields author, replier and participant interests without a separate synthetic originator."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The Membership row already states retained MembershipProjection-row-only recovery and fail-closed behavior when required scope is unavailable. This accepted correction is supporting evidence and is outside the revision's changed paths."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Production recovery consults `membership_scope/1`, which reads the retained MembershipProjection row by membership ID. The current test-only repair must not alter this source or any invalidation classification."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Committed projector changes are published after successful projection transactions with projector, event, metadata and changes. The adapter tests verify classification at this established boundary."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture requires each view-specific query to return one coherent view model and complete interests, while Memba-specific notification mapping remains in the app."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused process tests should use supervised processes and deterministic synchronization. The existing Agent-backed Binding counters already provide exact one-versus-two read evidence without sleeps."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The sole approved acceptance scenario, `Bob sees Alice join without reloading`, is already green with its prediction matched. This bounded technical test-proof revision has no appropriate new acceptance scenario."
      }
    ],
    "constraints": [
      "Preserve the prior blocked run and all eight review-revise candidates as provenance only. Revision 8's independent verdict is a rejection requiring repair, not acceptance.",
      "Limit changed paths to `web/test/memba_web/live_query/memba_read_model_source_test.exs`.",
      "Construct dashboard message rows by calling public `MembaWeb.MemberDashboardPresentation.present_message_rows/2`; do not reproduce another hand-authored presentation result.",
      "Use one canonical root identity: message ID, conversation ID, audited reply conversation ID and audited reply-to ID must all be `conversation-1`.",
      "Use `person-author` as both sender and originator through the presenter. Do not retain or replace `person-originator` elsewhere in the expected set.",
      "Use a distinct `person-replier` as latest replier and include it in `participant_ids` alongside `person-participant`; preserve both rendered identities in expected interests.",
      "Set reply_count consistently for the fixture, preferably two replies for the two distinct non-originator participant identities, and assert that coherence explicitly.",
      "Keep the full production dashboard and detail interest lists unchanged when registering with Binding or intersecting projector invalidations.",
      "Preserve all eleven family expectations from revision 8: Club for both; Membership dashboard club_members/person_club and detail person_club; represented Person for both; Group dashboard only; GroupMembership collection/exact scopes for dashboard and exact participation for detail; Role dashboard only; Message dashboard conversation/conversation_messages/club breadth and detail exact conversation scopes; ConversationGroupAccess dashboard group/access/conversation and detail access/conversation; Follow detail only; both delivery contributors detail only.",
      "Preserve the Membership loader counts: other-club current Person one/one, selected-club current Person two/two, and another selected-club Person dashboard two/detail one.",
      "The focused suites are currently green but the dashboard proof is false. Predict they remain green after the fixture repair; if they do not, diagnose the actual production-derived dependency instead of deleting interests, weakening assertions or changing production code.",
      "Prepare one complete candidate for fresh independent review with task 008A still unchecked and no Slack contact or publication action."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List the changed paths and confirm the only changed path is `web/test/memba_web/live_query/memba_read_model_source_test.exs`.",
      "Show that `dashboard_result/0` obtains its message row from public `MemberDashboardPresentation.present_message_rows/2` using one canonical root conversation input.",
      "Report the coherent identities and explicit assertions: root message ID equals conversation ID, originator ID equals sender ID, latest replier differs from the originator and appears among rendered participant IDs, and reply_count is consistent with this fixture's participant list.",
      "Confirm the audited reply remains linked to the canonical root through both conversation_id and reply_to_message_id.",
      "Report the exact complete dashboard-interest cardinality as 30 and confirm the expected set drops only `{:person, \"person-originator\"}` while retaining `person-author`, `person-replier` and `person-participant`.",
      "Report that the complete detail-interest set remains 13 and that its coherent root/message/author assertions are unchanged.",
      "Report all eleven projector-family intersections for both complete interest sets and confirm their semantics are unchanged from revision 8.",
      "Report the positive and negative loader counts unchanged: other-club current Person one/one, selected-club current Person two/two, and another selected-club Person dashboard two/detail one.",
      "Report successful exit status, test count and failure count for the focused adapter/Binding command and the two-query command, plus format and diff-check results.",
      "Confirm no application code, query code, presenter code, messaging code, migration matrix, package, LiveView, projector, event, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed.",
      "Confirm task 008A remains unchecked and the candidate is returned for fresh independent review without Slack contact, impersonation, acceptance or publication approval."
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
      },
      {
        "base_sha": "c0227b578a9196b34098aba0f76c6e163c155237",
        "head_sha": "3da496a01ae312d0a19e6b70c28f96cd2308aafe",
        "packet_id": "task-008a-c0227b5-selected-club-authority-revision-7",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      },
      {
        "base_sha": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
        "head_sha": "d8ab20fd26aee73ce1bee85c7aa965175528ee7b",
        "packet_id": "task-008a-3971e31-coherent-audit-revision-8",
        "reason": "review_revise",
        "task_id": "task-008a",
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
      }
    ],
    "scenario_focus": null
  }
}