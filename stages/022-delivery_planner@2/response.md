{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
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
        "origin": "Adapter-completion portion of approved implementation step 4, corrected after review to distinguish valid broad scopes from malformed known notifications.",
        "coverage": [
          "All actual event families published by the eleven in-scope projectors",
          "Exact collection, identity and authorization invalidations for valid complete events",
          "Only evidenced broader scopes for valid events, including MessageSent club-conversation scope and role/permission fan-out",
          "Legacy MemberRemoved scope recovery from the retained membership row",
          "A stable application-owned exception for recognized malformed or unsupported projector/event pairings",
          "The same visible contract-violation behavior during ordinary notification handling and bind-window reconciliation",
          "Full publisher-envelope validation with structurally incomplete envelopes ignored",
          "ConversationFollow MessageSent true/default behavior and false no-op behavior",
          "Replay-only EmailDeliveryOpened no-op behavior for both delivery projectors",
          "Exact tuple matching and unrelated-projector isolation",
          "An eleven-row projector/event-family coverage table and fresh independent review"
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
        "scope": "Accepted package adoption by dashboard and conversation detail while retaining application-owned policy."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008a"
        ],
        "scope": "Correct and prove the app-owned notification adapter against actual projector/event families, evidenced broad scopes, no-op publications, full envelopes and lifecycle-visible malformed-event contract violations."
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
    "planner_note": "The trusted checkpoint preserves tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Task 008A remains the first unchecked line and retains both rejected candidate origins under the same task identity. The latest candidate corrected event-family dispatch, false auto-follow, replay-only delivery events and unsupported synthetic fallbacks, but independent review found that returning {:error, ...} violates the frozen Source classifier contract: ordinary handling wraps it as invalid_classification and bind-window reconciliation drops it. This revision adds a stable application-owned exception path, complete publisher-envelope filtering, focused proof through both binding paths and the omitted eleven-row coverage table without changing the generic package. No todo edit or further split is needed because these are bounded review gaps within task 008A. The sole approved acceptance scenario is already accepted and green; this adapter lifecycle revision has no separate agreed scenario, so scenario_focus is null and focused technical proof is used."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-59e50fa-contract-lifecycle-revision-3",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "59e50fa26a52a8d3376a356546c3ba9309d79681",
    "outcome": "Make recognized Memba read-model publisher contract violations fail through one stable application-owned exception during both ordinary notification handling and bind-window reconciliation, while ignoring structurally incomplete outer envelopes and preserving the candidate’s corrected eleven-family invalidation behavior.",
    "scope": [
      "Add a dedicated application-owned exception module under `web/lib/memba_web/live_query/` with stable inspectable projector, source-event module and reason fields plus a deterministic message.",
      "Change `MembaWeb.LiveQuery.MembaReadModelSource` so recognized unsupported projector/event pairings and recognized events missing required identities raise that exception instead of returning a classifier result outside `LiveQuery.Source`’s frozen `:ignore | {:ok, invalidations}` contract.",
      "Require the complete publisher envelope before classification: projector, source_event, metadata and changes must all be present with the types published by `Memba.ReadModelChanges`; structurally incomplete or mistyped outer envelopes remain ignored.",
      "Keep complete notifications for unrelated projector modules ignored, while complete notifications for recognized projectors with unsupported event types or missing inner identities fail visibly.",
      "Update the existing adapter tests so all malformed-current-event, unrecoverable legacy MemberRemoved, malformed delivery, unsupported pairing and missing-identity cases assert the same stable application exception and its exact fields.",
      "Add focused ordinary-lifecycle proof by binding a minimal query to the Memba source, passing a complete malformed Membership notification through `LiveQuery.Binding.handle_notification/2`, and proving the application exception is raised rather than wrapped as invalid_classification.",
      "Add focused bind-window proof with a connected test socket and a query load that queues the same complete malformed Membership notification during its first read, proving reconciliation raises the same application exception instead of silently discarding it.",
      "Add focused outer-envelope cases for missing metadata, missing changes, non-map metadata and non-map changes, retaining existing unrelated-projector and unrelated-message isolation.",
      "Preserve the current candidate’s corrected actual-event dispatch, exact and evidenced broad invalidations, legacy retained-row recovery, false auto-follow no-op, EmailDeliveryOpened no-op and exact tuple matching.",
      "Return an eleven-row completion-evidence table covering Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery."
    ],
    "scope_exclusions": [
      "Do not modify `packages/live_query/**`; the generic Source and Binding contracts remain frozen.",
      "Do not modify the dashboard or conversation-detail LiveViews, query modules or accepted query-interest vocabulary.",
      "Do not add tasks 008B through 008F query modules or migrate any remaining LiveView.",
      "Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms or UI behavior.",
      "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance feature or package documentation.",
      "Do not restore synthetic partial-event, arbitrary committed-change, delivery-row-lookup or global fallback behavior.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice acceptance scenario.",
      "Do not perform tasks 010 or 011 and do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.",
      "Do not mark task 008A complete; deterministic independent review owns acceptance."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model permits broad invalidation only for valid events that genuinely lack exact scope and requires known malformed Membership notifications with unrecoverable Person identity to surface a contract violation rather than refresh a partial, club-wide or global scope."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked obligation and owns actual projector-family coverage, exact matching, visible malformed-Membership handling, fallback auditing and fresh independent review."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted baseline requires preservation of both task-008a candidate origins and binds this new packet to current HEAD rather than the artifact’s predecessor pre_planner_head."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest candidate reported 25 adapter tests and 8 accepted query-vocabulary tests passing and correctly narrowed actual event dispatch, legacy recovery and projector no-ops, but it returned contract violations as an out-of-contract classifier tuple and omitted the required coverage table."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review requires one application-owned stable failure path visible during ordinary handling and bind-window reconciliation, full-envelope checks for metadata and changes, focused lifecycle proof, and the omitted eleven-row projector/event table."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The normative matrix defines the eleven projector families, exact and legitimate broad interests, false auto-follow and replay-only opened no-ops, retained-row legacy MemberRemoved recovery, and the distinction between malformed payloads and valid broader event shapes."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "The committed publisher envelope has four fields—projector, source_event, metadata and changes—and is emitted only after the projection transaction commits."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Memba owns notification translation and authorization policy while the generic local package owns only the reusable opaque query-binding mechanism."
      },
      {
        "path": "web/lib/memba/read_model_changes.ex",
        "facts": "`publish/4` always broadcasts projector, source_event, metadata and changes; its message type requires a module, event struct and map values for metadata and changes."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Current classification accepts envelopes containing only projector and source_event, and `contract_violation/3` returns `{:error, ...}` even though the generic classifier contract does not allow that result."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "The focused suite covers the corrected eleven-family mappings but currently asserts out-of-contract error tuples directly and lacks Binding-level ordinary and bind-window visibility proof plus missing-metadata/missing-changes cases."
      },
      {
        "path": "packages/live_query/lib/live_query/source.ex",
        "facts": "The frozen generic classifier type is exactly `:ignore | {:ok, [term()]}`; no application-specific error result belongs in this package API."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "Ordinary handling wraps any classifier result outside the frozen contract as invalid_classification, while bind-window reconciliation currently ignores every result except `{:ok, list}`; exceptions are not rescued by either path."
      },
      {
        "path": "packages/live_query/test/live_query/binding_test.exs",
        "facts": "Existing generic tests show how to create a connected socket and queue a notification during the first query read, providing the deterministic pattern for adapter-level bind-window proof without sleeps."
      },
      {
        "path": "web/lib/memba_web/live/member_dashboard_live.ex",
        "facts": "The accepted dashboard consumer routes committed read-model notifications through `Binding.handle_notification/2`; an application classifier exception therefore remains visible through its ordinary LiveView lifecycle without a consumer change."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/show.ex",
        "facts": "The accepted conversation-detail consumer also routes committed read-model notifications through `Binding.handle_notification/2`; no special LiveView error tuple or package API extension is needed."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use a separate module file for the exception, keep process tests deterministic without sleeps or polling, and use supervised cleanup for any started process."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The iteration’s sole approved acceptance scenario is already green with its prediction matched, so this technical revision must not fabricate another scenario-first cycle."
      }
    ],
    "constraints": [
      "Limit implementation changes to `web/lib/memba_web/live_query/read_model_contract_violation_error.ex`, `web/lib/memba_web/live_query/memba_read_model_source.ex` and `web/test/memba_web/live_query/memba_read_model_source_test.exs`; report an unavoidable compile conflict before expanding scope.",
      "Use a dedicated exception module rather than nesting another module in the adapter file.",
      "Keep the exception application-owned and stable: expose the projector module, source-event module and reason as inspectable fields and use a deterministic non-sensitive message.",
      "Do not include the full event payload in the exception; preserve the current event-module-level identity and reason.",
      "Require metadata and changes to be maps as defined by the actual publisher; missing or mistyped outer-envelope fields are ignored before projector dispatch.",
      "Once a complete envelope identifies a recognized projector, unsupported actual event pairings or missing required inner identities must raise the application exception and emit no invalidations.",
      "Use actual event structs and actual projector/event pairings as ground truth. Narrow maps may test malformed envelopes but must not establish invented valid event variants.",
      "Preserve exact tuple equality and every legitimate collection-entry/exit scope; do not replace precise invalidations with unconditional global invalidation.",
      "Keep the retained Membership projection row as the only evidenced legacy MemberRemoved recovery source and do not restore arbitrary changes-map recovery.",
      "Keep false `sender_follows_conversation` and replay-only `EmailDeliveryOpened` publications ignored.",
      "Both delivery projectors must retain identical exact keys for the five state-changing delivery event families.",
      "Use deterministic Binding-level tests with a connected socket and a queued mailbox notification; do not use sleeps or liveness polling.",
      "Prepare evidence for fresh independent review and leave the todo line unchecked."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs"
    ],
    "completion_evidence_required": [
      "List every changed path and summarize the exception, envelope-classifier and focused-test changes.",
      "Report successful exit status and test count for the focused adapter command.",
      "Report successful exit status and test count for the accepted dashboard and conversation-detail query-vocabulary regression command.",
      "Show that a complete malformed Membership notification raises the same stable application exception, with exact fields, both through ordinary `Binding.handle_notification/2` and bind-window reconciliation.",
      "Show that notifications missing metadata or changes, or carrying non-map metadata or changes, return `:ignore` and do not reach recognized-projector dispatch.",
      "Show that unrelated projectors and unrelated messages remain ignored while a complete recognized unsupported pairing raises the application exception.",
      "Show that a Membership notification with club scope and unrecoverable Person identity raises the contract exception and emits no scoped or global Membership fallback.",
      "Confirm the corrected candidate behavior remains intact: retained-row-only legacy MemberRemoved recovery, exact tuple isolation, false auto-follow no-op, both delivery contributors’ exact five-family mappings and replay-only EmailDeliveryOpened no-op.",
      "Provide a concise eleven-row table naming each in-scope projector family, its actual source-event families, exact or evidenced broad invalidations, no-op events, any evidenced recovery source, and malformed/unsupported behavior.",
      "Confirm no file under `packages/live_query`, no accepted LiveView/query consumer, no projector/event/schema, and no plan, todo, matrix, ADR or feature file changed.",
      "Report formatting and `git diff --check` results in the worker summary without running an unscoped repository suite.",
      "Report any actual publisher shape that conflicts with the complete-envelope or exception contract and leave the todo unchecked if such a conflict remains."
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
      }
    ],
    "scenario_focus": null
  }
}