{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7137b1aafe51f2768b2b3bf36037900c0534b38b",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
      "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports."
    ],
    "pending_obligations": [
      {
        "task_id": "task-007b",
        "todo_line": "- [ ] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
        "origin": "Second bounded package-extraction slice of baseline task 007, reserved for adopting the package in the two accepted vertical consumers after the package API and independent tests exist.",
        "status": "prepared",
        "coverage": [
          "Development path dependency sufficient for the web application to compile against the accepted local package",
          "Dashboard and conversation-detail adoption of LiveQuery.Query and LiveQuery.Binding",
          "Memba notification classification and authorized query loaders remaining application-owned",
          "Removal of superseded app-private generic modules and duplicated generic test support",
          "Focused preservation of both accepted consumers' mount, route rebind, scoped refresh, transient-state and access-error behavior",
          "No remaining member-page migration, Docker release work or repository quality-gate integration"
        ],
        "replaces": [
          "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
          "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008",
        "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
        "origin": "Remaining application-adapter and query work from approved plan task 4 after the accepted dashboard and conversation-detail mappings.",
        "status": "pending",
        "coverage": [
          "Every remaining projector and event mapping recorded in the accepted migration matrix",
          "Collection, identity and authorization interests",
          "Old and new scopes where available",
          "Conservative club, family or global fallbacks when exact scope is unavailable",
          "Remaining fresh authorized view-specific queries",
          "No application-specific policy in the generic package"
        ],
        "replaces": [
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
        "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
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
        "origin": "Approved plan task 6, retaining supported production release and repository quality-gate integration after package extraction and consumer adoption.",
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
        "origin": "Remainder of baseline task 011 after its approved stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A and moved earlier.",
        "status": "pending",
        "coverage": [
          "Remaining focused regression proof for every migrated member page",
          "Any still-open migration-matrix proof gaps after tasks 008 and 009",
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
        "scope": "Adoption of the accepted package by the two accepted vertical consumers and removal of the provisional app-private generic contract.",
        "pending_task_ids": [
          "task-007b"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Complete remaining Memba notification adapter mappings and authorized queries.",
        "pending_task_ids": [
          "task-008"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Migration of the five remaining in-scope member LiveViews.",
        "pending_task_ids": [
          "task-009"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Production package, Docker release and repository quality-gate integration.",
        "pending_task_ids": [
          "task-010"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Remaining per-page proof, residual package lifecycle/race coverage and final exact-state validation.",
        "pending_task_ids": [
          "task-011"
        ],
        "accepted_task_lines": []
      }
    ],
    "planner_note": "The trusted checkpoint and current todo preserve tasks 001, 003, 004, 005, 006, 006A and 007A exactly as accepted. Independent review accepted task 007A's standalone package with no candidate origins, so its package files are accepted evidence rather than provenance for a revision. Task 007B is already the correctly bounded first unchecked line and retains the second half of the earlier task-007 split: add only the web dependency needed to compile against the package, adopt LiveQuery.Query, LiveQuery.Source and LiveQuery.Binding in the two proven consumers, keep all Memba mapping and authorization policy in the application, and remove the duplicate provisional generic implementation. Tasks 008 through 011 and all prior replacement lineage remain unchanged, so no todo edit, further split, reorder or prerequisite is needed. Task 007B is technical adoption of already-accepted behavior. The iteration's sole agreed scenario is already green and accepted; reactivating it would fabricate a new red cycle, while no conversation-detail acceptance scenario is approved. The packet therefore uses focused package, adapter, query and LiveView regression proof with scenario_focus null."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7137b1aafe51f2768b2b3bf36037900c0534b38b",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-007b-7137b1a-consumer-adoption-1",
    "task_id": "task-007b",
    "todo_line": "- [ ] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7137b1aafe51f2768b2b3bf36037900c0534b38b",
    "outcome": "Make the accepted dashboard and conversation-detail verticals compile and run against the local LiveQuery.Query, LiveQuery.Source and LiveQuery.Binding package API; retain the Memba notification adapter, fresh-authorized loaders, invalidation vocabulary and access/navigation policy in the application; remove the superseded app-private generic modules and duplicated generic test support; and prove both consumers preserve mount and route-rebind lifecycle, scoped refresh, transient state and access-error behavior.",
    "scope": [
      "Add the minimal `{:live_query, path: \"../packages/live_query\"}` dependency required for `web` to compile against the accepted local package. Update `web/mix.lock` only if Mix requires a lock change; leave final supported-environment, Docker and quality-gate integration for task 010.",
      "Change `MembaWeb.MemberDashboardLive` and `MembaWeb.MemberMessageLive.Show` to use `LiveQuery.Binding` while preserving their existing bind, rebind, notification handling, shell synchronization, navigation and error behavior.",
      "Change `MembaWeb.MemberDashboardQuery` and `MembaWeb.MemberMessageDetailQuery` to construct `LiveQuery.Query` descriptors. Keep their stable IDs, one-result assigns, loader shapes, interests, fresh-authority reads and application-owned query composition unchanged.",
      "Keep `MembaWeb.LiveQuery.MembaReadModelSource` in the app and change only its generic source dependency to `LiveQuery.Source`. Preserve every current projector classification, invalidation tuple, conservative fallback, subscription and matching rule.",
      "Update app-owned query and Memba source tests to use `LiveQuery.Query` and `LiveQuery.Source` while preserving their behavioral assertions.",
      "Delete the superseded `MembaWeb.LiveQuery.Binding`, `MembaWeb.LiveQuery.Query` and `MembaWeb.LiveQuery.Source` modules after all application references use the package.",
      "Remove the duplicated web-level generic binding test and its MembaWeb fixture once the accepted package-owned binding and lifecycle tests remain the authoritative generic proof.",
      "Update `docs/iterations/067-live-projection-queries/extraction-contract.md` only as needed to replace stale implementation-location references with the accepted `LiveQuery` package modules and package-owned tests; do not alter the frozen semantics.",
      "Run focused package, query, source-adapter, dashboard and conversation-detail checks and report exact command exits and observed evidence."
    ],
    "scope_exclusions": [
      "Do not change the package callback arities, loader result shapes, registration state, interest replacement, matching, bind-window reconciliation, reconnect or cleanup semantics accepted in task 007A.",
      "Do not move `MembaWeb.LiveQuery.MembaReadModelSource`, projector modules, event recognition, invalidation tuples, authorization reads, access transitions or navigation policy into `packages/live_query`.",
      "Do not add remaining projector mappings, conservative fallbacks or page-specific queries reserved for task 008.",
      "Do not migrate group creation, settings, message composition, delivery detail or invitation LiveViews; task 009 owns those pages.",
      "Do not change staff stream-backed views or add a stream adapter.",
      "Do not edit Docker, release, `bin/dev`, CI or repository quality-gate integration; task 010 owns those supported-environment changes.",
      "Do not expand remaining-page proof or claim final iteration validation; task 011 owns residual proof and final `dev check`.",
      "Do not edit acceptance features, ADRs, the approved plan, migration-matrix policy, routes, domain events, projection schemas, migrations or UI behavior.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario, and do not invent a conversation-detail acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite in this packet.",
      "Do not mark the todo line complete."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved architecture puts generic query, source and binding mechanics in a local path-dependency package while Memba-specific notification mapping, authorization and query implementations remain in the app. Dashboard and conversation detail are the two accepted pre-freeze vertical proofs, and package production/quality-gate integration is a later obligation."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 007B is the first unchecked line. It owns replacement of the two accepted consumers' provisional generic modules with the accepted package API and removal of the superseded app-private generic contract; tasks 008 through 011 remain separate."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint records tasks through 007A as accepted, 007B as the first remaining obligation, no required candidate origins and the previous 007A packet identity. This packet is bound to current checkpoint HEAD, not the artifact's pre_planner_head."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted task 007A: the package preserves the frozen API and lifecycle, its fifteen package tests passed, and the existing web consumers were intentionally left unchanged for 007B. The review records no candidate origins."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The accepted 007A worker created the standalone package and reported successful formatting, warnings-as-errors compilation, fifteen package tests and a no-Memba/Commanded dependency check. It explicitly left web consumers and provisional modules untouched for this task."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The sole approved iteration scenario, Bob sees Alice join without reloading, already completed green with 180 tests and zero failures. It must not be reset to manufacture scenario-led feedback for this technical adoption."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "This freezes stable query identity, one assign, one-argument loaders, opaque interests, source callback arities, one owner subscription, subscribe-before-read, bind-window reconciliation, atomic replacement, access-error clearing and owner-controlled navigation. Adoption may change namespaces and implementation locations but not these semantics."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted decision requires the reusable binding mechanism to live in a local package independent of Memba and Commanded, while Memba queries and notification mapping remain application-owned."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "The accepted `LiveQuery.Binding` exposes the `bind/4`, `rebind/3` and `handle_notification/2` API needed by both consumers, stores registrations on the socket, subscribes once before connected reads, replaces result and interests together, and returns access errors to the owner."
      },
      {
        "path": "packages/live_query/lib/live_query/query.ex",
        "facts": "The accepted `LiveQuery.Query` preserves the stable id, atom assign, one-argument loader and `{:ok, result, interests}` or `{:error, reason}` contract currently used by both app-owned queries."
      },
      {
        "path": "packages/live_query/lib/live_query/source.ex",
        "facts": "The accepted `LiveQuery.Source` preserves zero-argument subscribe, one-argument classify and two-argument matches callbacks while treating Memba interests and invalidations as opaque values."
      },
      {
        "path": "packages/live_query/test/live_query/binding_test.exs",
        "facts": "Package-owned tests cover disconnected and connected binding, subscribe-before-read, one shared owner subscription, relevant-only refresh, atomic interest replacement, route rebind, access-error clearing and deterministic bind/rebind reconciliation."
      },
      {
        "path": "packages/live_query/test/live_query/lifecycle_test.exs",
        "facts": "Package-owned lifecycle tests cover fresh connected owners, reconnect behavior and monitored subscriber cleanup without a query process or explicit unsubscribe callback."
      },
      {
        "path": "web/mix.exs",
        "facts": "The web application currently has no `:live_query` dependency. Task 007B requires the minimal local path dependency so its two consumers can compile against the package; Docker and quality-gate support remain task 010."
      },
      {
        "path": "web/lib/memba_web/live/member_dashboard_live.ex",
        "facts": "The dashboard currently aliases the provisional Binding and uses `bind/4`, `handle_notification/2` and `rebind/3`. Its existing error handlers, route state, transient picker state and shell synchronization must remain owner-controlled and unchanged."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/show.ex",
        "facts": "Conversation detail currently aliases the provisional Binding for initial bind, notification refresh and explicit rebind. Its forbidden/not-found handling, access-loss navigation, reply state, follow state and receipt disclosure state must remain application-owned."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The dashboard query currently constructs the provisional Query descriptor and rereads active-club authority from authenticated email on every load. Only the generic descriptor namespace changes; its coherent dashboard assign and complete interests remain in the app."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "The composed conversation-detail query constructs one descriptor with collection, represented-person, exact-follow, delivery and authorization interests. Its fresh-authorized loader and application vocabulary remain unchanged."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "This application adapter owns PubSub subscription, projector and event classification, scoped invalidations, conservative fallbacks and exact matching. It remains under the MembaWeb namespace and should construct only the generic `LiveQuery.Source` value."
      },
      {
        "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
        "facts": "Accepted focused tests exercise connected dashboard refresh, member entry/exit and ordering, represented Person and role changes, route rebind and old-interest replacement, unrelated-scope isolation, transient-state preservation and fresh access-loss behavior."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/show_test.exs",
        "facts": "Accepted focused tests exercise reply entry, represented-author refresh, unrelated-scope isolation, exact follow invalidation, two-projector delivery convergence, transient reply/disclosure preservation and fresh access-loss navigation."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests should use deterministic process synchronization and monitoring, avoid sleeps and process liveness polling, and use narrow Mix test targets while diagnosing changes."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView tests should verify observable owner behavior. The ordinary-assign consumers remain LiveView-owned; staff streams are outside this package-adoption task."
      }
    ],
    "constraints": [
      "Treat the accepted package implementation and `extraction-contract.md` semantics as frozen; this task changes dependency and namespace ownership, not behavior.",
      "Use `LiveQuery.Binding`, `LiveQuery.Query` and `LiveQuery.Source` directly rather than adding compatibility wrappers under `MembaWeb.LiveQuery`.",
      "Keep the package independent of Memba, Commanded, Ecto, projector names, event names, invalidation tuple vocabulary, authorization and navigation policy.",
      "Keep one coherent `:dashboard` result and one coherent `:message_detail` result; do not split either consumer into multiple query assigns.",
      "Preserve fresh authorization inputs and the existing forbidden/not-found behavior on initial read, route rebind and notification refresh.",
      "Preserve subscribe-before-read, one owner subscription, bind-window reconciliation and complete interest replacement by delegating to the accepted package unchanged.",
      "Adding the minimal web path dependency is part of making 007B compile; final lock metadata verification, Docker copying, release inclusion and quality-gate execution remain task 010.",
      "Remove only the superseded generic modules and duplicated generic test support. Retain `MembaWeb.LiveQuery.MembaReadModelSource` and all app-owned query and consumer tests.",
      "If package adoption exposes an actual API incompatibility, report it as unresolved with exact compile or test evidence instead of redesigning the frozen contract or keeping silent duplicate implementations."
    ],
    "focused_validation": [
      "(cd packages/live_query && MIX_ENV=test mix compile --warnings-as-errors)",
      "(cd packages/live_query && mix test)",
      "dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_message_detail_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "dev test test/memba_web/live/member_dashboard_live_test.exs",
      "dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs",
      "bin/mix deps.tree live_query",
      "bin/mix format --check-formatted",
      "(cd packages/live_query && mix format --check-formatted)",
      "if grep -R -n -E 'MembaWeb[.]LiveQuery[.](Binding|Query|Source)' web/lib web/test; then exit 1; else exit 0; fi",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed and deleted path, distinguishing the minimal web dependency, package API alias adoption, retained app adapter/query code, removed provisional modules, removed duplicate generic test support and any narrow extraction-contract reference repair.",
      "Show that `web` resolves `:live_query` from `../packages/live_query` and that no compatibility copy of Binding, Query or Source remains under `MembaWeb.LiveQuery`.",
      "Report successful exits and concise evidence for the package compile/tests and the focused app query, source-adapter, dashboard and conversation-detail test commands.",
      "Confirm the dashboard still proves connected refresh, route rebind, transient-state preservation and fresh access errors through `LiveQuery.Binding`.",
      "Confirm conversation detail still proves scoped refresh, two-projector convergence, unrelated isolation, transient-state preservation and access-loss navigation through `LiveQuery.Binding`.",
      "Confirm `MembaWeb.LiveQuery.MembaReadModelSource`, all projector/event mappings, invalidation tuples, fresh-authorized loaders and owner navigation policy remain application-owned.",
      "Report formatting, dependency-tree, stale-namespace and diff-check results.",
      "Report any unresolved package API, dependency or lifecycle conflict explicitly; do not mark the todo line complete."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}