{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
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
        "origin": "Adapter-completion portion of approved implementation step 4, corrected through seven rejected independent-review revisions and Matt's explicitly delegated bounded revision-8 fixture and matrix repair.",
        "coverage": [
          "All actual event families published by the eleven source-recognized projectors",
          "Exact Membership invalidations and selected-club isolation already implemented by revision 7",
          "Coherent production-shaped dashboard interests with root message identity equal to conversation identity",
          "Coherent production-shaped conversation-detail interests containing at least the root conversation entry and its represented author",
          "Unchanged positive and negative Binding loader-count proof using both complete production interest lists",
          "A complete two-query audit against all eleven producer families without synthetic interest subsets",
          "Retained MembershipProjection-row-only recovery for genuine legacy MemberRemoved omissions",
          "Fail-closed contract violations when the retained row cannot recover required scope",
          "Corrected Membership migration-matrix wording and fresh independent review"
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
      },
      {
        "base_sha": "c0227b578a9196b34098aba0f76c6e163c155237",
        "head_sha": "3da496a01ae312d0a19e6b70c28f96cd2308aafe",
        "packet_id": "task-008a-c0227b5-selected-club-authority-revision-7",
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
        "scope": "Complete task 008A by replacing the incoherent reduced audit fixtures with production-shaped dashboard and conversation-detail results, rerunning both complete-interest family and loader-count proofs unchanged, correcting Membership legacy recovery documentation to retained-row-only, and obtaining fresh independent review."
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
    "planner_note": "The clean binding checkpoint is 3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9. Tasks 001, 003, 004, 005, 006, 006A, 007A and 007B remain preserved exactly as accepted. Task 008A remains the first unchecked line with unchanged identity and wording, so todo.md required no edit. Previous run 01M41YZDCWG8JP1ATXNYGF3DZZ remains blocked; revision 7 is retained as the seventh review-revise candidate and is not accepted evidence. Matt explicitly delegated this bounded BB repair without another Slack interaction or publication. Inspection confirms both review gaps. `dashboard_interests/0` describes a root row whose `message_id` differs from `conversation_id`, and its representative reply points at the inconsistent synthetic root. `conversation_detail_interests/0` supplies a root message while leaving `conversation_entries` empty, although `MemberMessageDetail.load/3` rejects an empty conversation and every successful result creates at least the root entry with its author. The adapter intentionally ignores `changes` for legacy Membership recovery and reads only the retained `MembershipProjection` row; its focused test rejects synthetic changes-map recovery. The worker packet therefore changes only the focused source test and the Membership row of migration-matrix.md, preserves revision-7 invalidations and query code, reruns the existing 44 adapter/Binding and 8 query tests, leaves 008A unchecked for independent review, and defers the full dev check to the final validation obligation. The sole approved acceptance scenario is already accepted and green, so this technical repair has no appropriate scenario-first run."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-3971e31-coherent-audit-revision-8",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9",
    "outcome": "Close both revision-7 review gaps by making the dashboard and conversation-detail audit fixtures represent possible successful production query results, retaining the existing exact invalidations and loader behavior, and documenting legacy Membership recovery as retained-row-only and fail-closed.",
    "scope": [
      "In `web/test/memba_web/live_query/memba_read_model_source_test.exs`, make the dashboard fixture's root `message_id` equal its `conversation_id`, as `MemberDashboardPresentation.present_message_rows/2` does for a root conversation.",
      "Update the representative MessageSent reply used by the eleven-family audit so both `conversation_id` and `reply_to_message_id` refer to that real canonical root; do not leave a second synthetic root identity.",
      "Make the conversation-detail fixture match a successful `MemberMessageDetail.load/3` result by supplying `conversation_entries` containing at least the root entry, with the same root message identity and a realistic represented author identity. Keep `message`, `conversation_audience`, the entry message and delivery root mutually coherent.",
      "Continue obtaining dashboard and detail interests by calling the production `MemberDashboardQuery.interests/1` and `MemberMessageDetailQuery.interests/1` functions, and register each complete returned list unchanged with Binding.",
      "Update the existing complete-set expectations or assertions as needed so the dashboard includes its canonical root message interest and detail includes its represented root message and author interests; ensure omitted root entries or divergent root/conversation IDs would fail the proof.",
      "Rerun the eleven-family audit against both coherent complete interest lists and preserve every expected exact intersection or justified ignore from revision 7.",
      "Rerun the positive and negative Membership loader-count proofs with both coherent complete interest lists unchanged: another-club current-Person stays at one read for both; selected-club current-Person advances both from one to two; another selected-club Person advances dashboard from one to two while detail stays at one.",
      "In only the `Membership.Projectors.Membership` row of `docs/iterations/067-live-projection-queries/migration-matrix.md`, replace the stale claim that legacy scope can be recovered from committed changes or the membership row. State that a genuine legacy omission is recovered only from the retained MembershipProjection row keyed by membership ID, and that missing or insufficient retained-row scope fails closed as a contract violation.",
      "Inspect adjacent matrix prose for the same stale changes-map recovery claim. Preserve adjacent wording that already correctly says retained membership row, and do not broaden this documentation repair beyond the Membership row unless an exact duplicate stale claim is present.",
      "Leave task 008A unchecked and return the bounded candidate for fresh independent review."
    ],
    "scope_exclusions": [
      "Do not modify `MembaReadModelSource`, `MemberDashboardQuery`, `MemberMessageDetailQuery`, either production presentation/loader module, any projector, event, projection schema, publisher, package module, LiveView, route, template or form.",
      "Do not rework or weaken revision-7 exact invalidations, selected-club `person_club` interests, person-wide producer support, strict equality, complete-envelope gating, malformed-event exceptions, legacy retained-row recovery, validated no-ops or unrelated-club isolation.",
      "Do not hand-pick a reduced interest subset for Binding or family assertions; use the full production `interests/1` results from coherent fixtures.",
      "Do not represent an empty `conversation_entries` list as a successful MemberMessageDetail result; the production loader fails when the conversation has no messages and builds an entry for every returned message.",
      "Do not claim the constructed fixtures are actual loader executions. Demonstrate that their fields and identities conform to the inspected production result shapes.",
      "Do not edit query tests merely to duplicate this repair; they are supporting regression validation and currently pass.",
      "Do not change any matrix row other than Membership merely for stylistic consistency. The adjacent Role row already documents retained-row recovery correctly.",
      "Do not edit the approved plan, todo, ADRs, acceptance feature or other project documentation.",
      "Do not implement tasks 008B through 011 or migrate another LiveView.",
      "Do not contact Slack, approve publication, accept task 008A, or treat the preserved blocked run as accepted.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; final iteration gates remain later work."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires coherent query results, complete represented-record interests, affected-query-only refresh, evidenced fallback behavior and a corrected migration matrix. The final full dev check belongs to later iteration validation."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation and explicitly requires actual projector-family proof, exact matching, corrected matrix evidence and fresh independent review."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The binding checkpoint is current HEAD 3971e31fdf4d3bc6afa3616dc7d55cbf7fdca2f9. All seven task-008a review-revise candidate origins, including rejected revision 7, must remain attached."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The independent revision-7 verdict is revise, not acceptance. It identifies exactly two gaps: incoherent reduced dashboard/detail audit fixtures and the Membership matrix's false committed-changes recovery claim."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "Revision 7 reported 44 adapter/Binding tests and 8 query tests green and established the exact selected-club invalidations and loader-count behavior. Preserve those code paths and rerun their focused proof after repairing realism and documentation."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "`dashboard_interests/0` currently gives a purported root row `message_id: \"message-root\"` but `conversation_id: \"conversation-1\"`; the representative reply also points at `message-root`. `conversation_detail_interests/0` uses root `conversation-1` but has `conversation_entries: []`. These helpers feed all three Membership loader-count tests and the eleven-family audit."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_presentation.ex",
        "facts": "`present_message_rows/2` receives root conversation summaries and derives `conversation_id` from the row's conversation ID or root message ID. Repository messaging invariants make a root message's ID equal its conversation ID, so the audit fixture must use one canonical root identity."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "`interests/1` derives conversation, conversation-message, conversation-access and exact message interests from each dashboard row, plus represented sender/originator/latest-replier/participant Person interests. A divergent synthetic root therefore misstates the complete production interest set."
      },
      {
        "path": "web/lib/memba_web/member_message_detail.ex",
        "facts": "`fetch_conversation/1` returns not-found for an empty conversation. Every successful `detail_assigns/5` result constructs `conversation_entries` from the nonempty message list, including the root and its sender identity."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "`interests/1` adds exact message and author Person interests only from `conversation_entries`; an empty list therefore omits dependencies that every successful production result contains."
      },
      {
        "path": "web/test/memba_web/member_message_detail_query_test.exs",
        "facts": "The production-shape query proof shows a coherent root entry uses the same root message/conversation ID and contributes both `{:message, root_id}` and `{:person, author_id}`; a reply points back to that root."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "`recover_legacy_membership_scope/1` consults only `membership_scope/1`, which casts the membership ID and reads the retained MembershipProjection row. The classifier validates the changes map envelope but does not recover Membership identity from its contents."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The Membership row incorrectly says a genuine historical omission can be recovered from committed changes or the membership row. The adjacent Role row already correctly specifies recovery from the retained membership row."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused process tests should remain deterministic; the existing supervised Agent-backed Binding read counters provide exact one-versus-two load evidence without sleeps."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The sole approved acceptance scenario, “Bob sees Alice join without reloading,” is already green with its prediction matched. This fixture/documentation revision has no appropriate new acceptance scenario."
      }
    ],
    "constraints": [
      "Preserve previous run 01M41YZDCWG8JP1ATXNYGF3DZZ as blocked and preserve revision 7 as rejected provenance. This packet is the explicitly delegated bounded repair, not a reset, renamed task, acceptance decision or publication approval.",
      "Limit changed paths to `web/test/memba_web/live_query/memba_read_model_source_test.exs` and `docs/iterations/067-live-projection-queries/migration-matrix.md`.",
      "Use one canonical root identity in each fixture. For the dashboard audit, the root `message_id`, row `conversation_id`, reply `conversation_id` and reply `reply_to_message_id` must agree.",
      "For detail, include at least the root in `conversation_entries`; its message ID, conversation ID and sender must agree with the detail's root/message and represented author. A root-only conversation is valid, while an empty successful conversation is not.",
      "Keep the two fixtures internally independent but realistic. Do not force unrelated dashboard and detail authors or deliveries to share IDs unless that is intentional and reflected in exact expected interests.",
      "Assert or otherwise demonstrate the complete interest sets as sets so the newly represented detail root message and author cannot be silently omitted and no unexpected broad key is hidden.",
      "Register the complete production interest lists unchanged with Binding. Do not delete broad or inconvenient interests to preserve expected loader counts.",
      "Preserve all eleven family expectations from revision 7: Club for both; Membership dashboard club_members/person_club and detail person_club; represented Person for both; Group dashboard only; GroupMembership dashboard collection/exact scopes and detail exact participation; Role dashboard only; Message dashboard conversation/conversation_messages/club breadth and detail exact conversation scopes; ConversationGroupAccess dashboard group/access/conversation and detail access/conversation; Follow detail only; both delivery contributors detail only.",
      "Preserve MessageSent club-conversation breadth, Role permission fan-out, ConversationGroupAccess conversation-wide authorization, complete-envelope gating, strict equality, malformed recognized-event exceptions, exact follow behavior, validated no-ops and both delivery contributors.",
      "Document only retained MembershipProjection-row recovery for genuine legacy Membership omissions. Synthetic committed changes must not supply scope, and absent or inadequate retained scope must surface the existing contract violation.",
      "The current tests are green but provide false coverage because their fixtures are impossible or incomplete. Do not manufacture an implementation failure; predict the repaired focused suites remain green and report any contrary result before broadening scope.",
      "If coherent result shapes cause an unexpected family intersection or loader count, diagnose and report the actual dependency instead of deleting an interest, weakening assertions or changing production code.",
      "Prepare one complete candidate for fresh independent review with task 008A still unchecked."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List the changed paths and confirm they are limited to the focused source test and the Membership migration-matrix row.",
      "Show the coherent dashboard fixture identities: root message ID equals conversation ID, and the audited reply's conversation and reply-to IDs both identify that root.",
      "Show the coherent detail fixture identities and its nonempty conversation_entries root entry, including the exact root message and represented author interests produced by `MemberMessageDetailQuery.interests/1`.",
      "Report the complete dashboard and detail interest-set assertions after fixture repair, including any expected key substitutions caused by canonicalizing the dashboard root.",
      "Report all eleven projector-family intersections for both coherent complete interest sets and confirm they remain semantically unchanged from revision 7.",
      "Report the positive and negative loader counts for both coherent complete interest lists: other-club current-Person one/one, selected-club current-Person two/two, and another selected-club Person dashboard two/detail one.",
      "Quote or summarize the corrected Membership matrix recovery rule: retained MembershipProjection row only, with a contract violation when required scope remains absent.",
      "Confirm adjacent matrix prose was checked and that no stale duplicate changes-map recovery claim remains in the affected section.",
      "Report successful exit status, test count and failure count for the focused adapter/Binding command and the two-query command, plus format and diff-check results.",
      "Confirm no application code, query code, query tests, package, LiveView, route, template, form, projector, event, projection schema, publisher, approved plan, todo, ADR or acceptance feature changed.",
      "Confirm task 008A remains unchecked and the candidate is returned for fresh independent review without Slack contact or publication approval."
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
      }
    ],
    "scenario_focus": null
  }
}