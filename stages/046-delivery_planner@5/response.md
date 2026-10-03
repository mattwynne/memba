{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b2466fc574c2110b09a5019d8c280658d035cd0",
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
        "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors.",
        "origin": "Adapter-completion portion of approved plan implementation step 4 and the previously pending task 008.",
        "status": "prepared",
        "coverage": [
          "Every committed projector and event family recorded in the accepted migration matrix",
          "Exact collection, identity and authorization invalidations for complete event scope",
          "Club-scoped or global conservative fallbacks when exact event, committed-change or projection-row scope is unavailable",
          "Compatibility events published by more than one projector",
          "Exact interest matching, unrelated-scope isolation and ignored unrelated projectors",
          "Both independently committed delivery contributors and delivery message-scope recovery"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008b",
        "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "origin": "Group-creation query portion of approved plan implementation step 4 and the previously pending task 008.",
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
        "origin": "Settings query portion of approved plan implementation step 4 and the previously pending task 008.",
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
        "origin": "Message-compose query portion of approved plan implementation step 4 and the previously pending task 008.",
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
        "origin": "Delivery-detail query portion of approved plan implementation step 4 and the previously pending task 008.",
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
        "origin": "Member-invitation query portion of approved plan implementation step 4 and the previously pending task 008.",
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
        "origin": "Remaining migration work from approved plan implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
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
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
        "origin": "Approved plan implementation step 6, retaining supported production release and repository quality-gate integration after package extraction and consumer adoption.",
        "status": "pending",
        "coverage": [
          "Final supported path-dependency metadata and lock state in web/mix.exs",
          "Docker dependency-copy and compilation ordering for the repository-local package",
          "Production release inclusion",
          "Explicit package test execution in the repository quality gate",
          "Supported local and CI environments"
        ],
        "replaces": [
          "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
        "origin": "Remainder of the final proof obligation after its stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A and moved earlier.",
        "status": "pending",
        "coverage": [
          "Remaining focused regression proof for every migrated member page",
          "Any still-open migration-matrix proof gaps after tasks 008A through 009",
          "Any remaining package mount, change, reconnect and race coverage not closed by task 007A",
          "Final full dev check on the exact delivered state"
        ],
        "replaces": [
          "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "candidate_origins": []
      }
    ],
    "candidate_origins": [],
    "coverage_map": [
      {
        "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
        ]
      },
      {
        "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
        ]
      },
      {
        "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
        ]
      },
      {
        "scope": "Accepted dashboard binding, scoped Memba invalidation, partial-scope fallbacks and open-dashboard vertical behavior proof.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
        ]
      },
      {
        "scope": "Accepted conversation-detail binding, multi-projector convergence, fresh-access proof, transient-state preservation and frozen extraction contract.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
        ]
      },
      {
        "scope": "Accepted stakeholder scenario and real committed-membership-projector-to-already-open-member-LiveView proof.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
        ]
      },
      {
        "scope": "Accepted standalone documented generic package and package-owned lifecycle, matching, race, duplicate/out-of-order and cleanup tests.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."
        ]
      },
      {
        "scope": "Accepted adoption of the local package by the dashboard and conversation-detail consumers, retained application-owned policy and removal of the provisional generic implementation.",
        "pending_task_ids": [],
        "accepted_task_lines": [
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior."
        ]
      },
      {
        "scope": "Complete and prove the app-owned committed-notification adapter against all accepted projector/event mappings, exact scopes, conservative fallbacks and unrelated-projector isolation.",
        "pending_task_ids": [
          "task-008a"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Introduce the five remaining fresh-authorized, one-result query boundaries from existing read APIs without moving transient LiveView state into those queries.",
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
        "scope": "Migrate the five remaining in-scope member LiveViews while preserving routes, access transitions, transient state, navigation, UI and delivery/conversation convergence.",
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
    "planner_note": "The trusted checkpoint and current todo preserve tasks 001, 003, 004, 005, 006, 006A, 007A and 007B exactly as accepted. Independent review accepted task 007B with no candidate origins after both established consumers adopted the package and retained the app-owned adapter and query policy. The former task 008 mixed a finite adapter-completion audit with five independent view-specific query boundaries, so it is replaced by tasks 008A through 008F: 008A owns the migration-matrix adapter mappings and fallbacks, and 008B through 008F each own one remaining page query. Every split line carries the former task-008 and approved-plan-task lineage; tasks 009 through 011 are unchanged. Task 008A is the first unchecked line and is a technical prerequisite. The sole approved acceptance scenario is already accepted and green, and no acceptance scenario exercises adapter classification in isolation, so this packet uses focused source-adapter and accepted-consumer vocabulary tests with scenario_focus null rather than manufacturing another scenario cycle."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b2466fc574c2110b09a5019d8c280658d035cd0",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008a-0b2466f-adapter-matrix-1",
    "task_id": "task-008a",
    "todo_line": "- [ ] 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b2466fc574c2110b09a5019d8c280658d035cd0",
    "outcome": "Finish and lock the application-owned translation from every committed projector/event family listed in the accepted migration matrix to the exact collection, identity and authorization invalidations consumed by live queries, retaining conservative club/global fallbacks whenever precise scope cannot be recovered, exact matching for unrelated-scope isolation, and `:ignore` for unrelated projectors.",
    "scope": [
      "Compare `MembaWeb.LiveQuery.MembaReadModelSource` directly with the actual `after_update/3` publishers and event clauses of the Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow, MemberEmailDelivery and MembaStaffEmailDelivery projectors.",
      "Complete any missing or incorrect classification for every event family recorded in the accepted migration matrix, including legacy membership/role compatibility events and no-op compatibility events published by the Club projector.",
      "Preserve exact collection-entry/exit and identity invalidations when club, group, conversation, membership, Person, role, message or delivery scope is present.",
      "Preserve partial useful scope and emit the documented club-family or global-family fallback when an event, committed `changes` value or committed projection lookup cannot provide the remaining scope.",
      "Keep both MemberEmailDelivery and MembaStaffEmailDelivery mapped to the same exact message-delivery collection and delivery identity, including recovery from committed changes or existing delivery rows and a delivery-family fallback when message scope remains unavailable.",
      "Keep source matching exact and demonstrate that a different club, group, conversation, Person, message or delivery does not match; known but incompletely scoped mapped notifications must fall back rather than disappear.",
      "Keep unrelated projectors and malformed non-notification messages ignored rather than turning all committed notifications into global refreshes.",
      "Expand the focused adapter tests so the matrix's publisher/event families, compatibility paths, exact scopes, fallback paths, delivery recovery and unrelated-projector behavior are explicit regression evidence."
    ],
    "scope_exclusions": [
      "Do not add the group-creation, settings, compose, delivery-detail or invitation query modules reserved for tasks 008B through 008F.",
      "Do not bind or migrate any remaining LiveView; task 009 owns consumer migration, result assigns, access transitions and transient-state preservation.",
      "Do not change the accepted `LiveQuery.Query`, `LiveQuery.Source` or `LiveQuery.Binding` package API or implementation.",
      "Do not move Memba projector names, event names, tuple vocabulary, projection lookups, authorization or navigation policy into `packages/live_query`.",
      "Do not change domain events, projectors, projection schemas, read APIs, routes, templates, forms, UI behavior or staff stream-backed views.",
      "Do not edit the acceptance feature, approved plan, ADRs, migration matrix or extraction contract.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario; this adapter-classification packet has no appropriate agreed red scenario.",
      "Do not perform Docker, release, `bin/dev`, CI or repository quality-gate integration reserved for task 010.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite.",
      "Do not mark the todo line complete."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model keeps projector/event translation in the Memba app, requires collection scopes for absent-row entry and exit, old/new scope where available, and conservative invalidation rather than silence when exact scope is unavailable. The generic package must remain independent of Memba and Commanded."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008A is the first unchecked line after splitting the former broad task 008. It owns only completion and focused proof of the app adapter; five page-specific query boundaries remain in tasks 008B through 008F."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint records tasks through 007B as accepted, the former task 008 as the first remaining obligation, no required candidate origins and the accepted 007B packet identity. This packet is bound to current checkpoint HEAD rather than the artifact's pre_planner_head."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted 007B with no candidate origins and confirmed that projector/event mappings, invalidation tuples, fresh-authorized loaders and owner policy remained application-owned while the two established consumers adopted the generic package."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The accepted 007B worker changed only package adoption and namespace ownership, reported the existing adapter tests green, and explicitly retained every current projector/event mapping and conservative fallback for later completion rather than moving them into the package."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The accepted matrix is the normative mapping inventory: Club, Membership, Person, Group, GroupMembership, Role, Message, ConversationGroupAccess, ConversationFollow and both delivery projectors map to collection and identity interests, with explicit partial-scope and global fallbacks. Staff streams and unrelated projector families are excluded."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Committed projection changes are published after projector transactions as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}`; the adapter must classify this post-commit shape rather than source events before projection commit."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture makes application queries declare collection and record interests while a Memba-owned adapter translates committed changes. Notifications trigger fresh authorized reads and must not patch view-model fields from events."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The current app-owned adapter subscribes to `ReadModelChanges`, recognizes eleven in-scope projector modules, emits opaque tuple invalidations, recovers delivery message scope from event fields, committed changes or projection rows, and uses exact tuple equality for matching. This is the implementation to audit and complete."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "Current focused tests cover subscription, representative membership, Person, role, message, group, access, follow and delivery scopes plus several fallback paths. They do not yet explicitly lock every publisher/event family and compatibility path listed by the matrix."
      },
      {
        "path": "web/lib/memba/membership/projectors/club.ex",
        "facts": "The Club projector publishes ClubCreated and ClubUpdated plus no-op compatibility events for group creation/email slug and role definition, permission and assignment/removal. Those compatibility notifications must map to the same logical group or role invalidations as their specialized projectors."
      },
      {
        "path": "web/lib/memba/membership/projectors/role.ex",
        "facts": "The Role projector publishes role definitions, permission grants, current and legacy assignment/removal events, and current and legacy membership-removal compatibility events. Membership-removal events may lack a single role identity and require member/permission scope or a conservative fallback."
      },
      {
        "path": "web/lib/memba/membership/projectors/membership.ex",
        "facts": "The Membership projector publishes current ClubMemberAdded/Removed and legacy MemberAdded/Removed events; collection entry and exit must invalidate the club-member collection and affected membership, Person and Person-clubs identities when present."
      },
      {
        "path": "web/lib/memba/membership/projectors/person.ex",
        "facts": "The Person projector publishes PersonCreated and all email-address add, verify, replace, primary-change and removal families. These events have Person scope but no reliable club scope, so represented Person and Person-email interests are exact while missing Person identity falls back globally."
      },
      {
        "path": "web/lib/memba/messaging/projectors/conversation_follow.ex",
        "facts": "ConversationFollow publishes explicit followed/unfollowed events and MessageSent auto-follow compatibility notifications. The adapter must derive the root conversation from `conversation_id` or root `message_id` and preserve member-specific follow scope where available."
      },
      {
        "path": "web/lib/memba/messaging/projectors/member_email_delivery.ex",
        "facts": "The member receipt projector publishes creation, delivered, delayed, bounced, spam-complaint and replay-only opened events. Status updates may require committed-change or row lookup to recover message scope from a delivery ID."
      },
      {
        "path": "web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex",
        "facts": "The staff delivery projector independently publishes the same delivery event families and contributes status reasons to member-facing joined results. Its later notification must map to the same exact message-delivery interest so results converge regardless of projector commit order."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The accepted dashboard query registers exact club, membership, Person, group, role, message and access interests plus both club-scoped and global fallback-family interests. Adapter tuple vocabulary and fallback shapes must remain compatible."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "The accepted conversation-detail query registers exact conversation, messages, follow, represented Person, delivery collection and delivery identity interests plus scoped/global fallbacks. Both delivery projectors must continue matching this same query vocabulary."
      },
      {
        "path": "packages/live_query/lib/live_query/source.ex",
        "facts": "The accepted generic source only stores injected subscribe, classify and matches callbacks and treats all interests and invalidations as opaque. No Memba event or tuple semantics belong in this package."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests should use narrow Mix targets and deterministic assertions, avoid sleeps and liveness polling, and keep process cleanup under test supervision."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The iteration's sole approved acceptance scenario, Bob sees Alice join without reloading, already completed green with 180 tests and zero failures. Adapter classification has no separate approved scenario, so scenario_focus is intentionally null."
      }
    ],
    "constraints": [
      "Treat the migration matrix's logical scopes and fallbacks as the accepted application contract; inspect actual projector clauses and event structs as implementation ground truth.",
      "Keep `MembaWeb.LiveQuery.MembaReadModelSource` application-owned and keep `LiveQuery.Source` generic and opaque.",
      "A known in-scope notification with incomplete scope must retain any useful exact keys and add the documented conservative fallback; do not silently ignore it or invent missing IDs.",
      "Do not replace precise invalidation with unconditional global invalidation when exact or club-scoped information is available.",
      "Keep entry and exit symmetric for membership, group membership, role assignment and conversation access collections so departing rows invalidate results even after the row is gone.",
      "Treat duplicate and out-of-order notifications as harmless invalidation hints; never patch query results from source events.",
      "Both delivery projectors are independent contributors to one joined result and must classify to compatible exact-message and exact-delivery keys.",
      "Preserve exact tuple equality matching and explicit query fallback registration unless direct evidence shows a matrix obligation cannot be represented; report such a conflict rather than redesigning the frozen package contract.",
      "Use actual event structs where practical in focused tests, with narrow map notifications only for missing-scope compatibility and fallback cases."
    ],
    "focused_validation": [
      "dev test test/memba_web/live_query/memba_read_model_source_test.exs",
      "dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs",
      "bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and summarize each adapter or focused-test change.",
      "Provide a concise projector/event-family coverage table showing the exact invalidations and fallback behavior now locked by tests.",
      "Report successful exit status and test counts for the focused adapter test command.",
      "Report successful exits for the accepted dashboard and conversation-detail query vocabulary regression tests.",
      "Confirm exact unrelated-club, group, conversation, Person, message and delivery scope remains isolated and unrelated projectors or malformed messages return `:ignore`.",
      "Confirm current and legacy membership/role compatibility events and Club-projector no-op compatibility publications are covered.",
      "Confirm both delivery projectors classify to compatible exact-message and delivery keys and that changes/row recovery plus broad fallback are covered.",
      "Confirm no Memba or Commanded dependency was added to `packages/live_query`, and report formatting and diff-check results.",
      "Report any projector/event family whose accepted matrix mapping cannot be satisfied from event, changes or projection state; do not mark the todo line complete when such a gap remains."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}