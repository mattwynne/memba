{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "1b40c6b59db1a8c2c22f4428946b014a06372766",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
    ],
    "pending_obligations": [
      {
        "task_id": "task-007a",
        "todo_line": "- [ ] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
        "origin": "First bounded package-extraction slice of baseline task 007, implementing the generic-package portion of approved plan task 3 while leaving accepted app consumers on the provisional modules until task 007B.",
        "status": "prepared",
        "coverage": [
          "A documented standalone local Mix application under packages/live_query",
          "Generic Query, Source and Binding modules preserving the frozen extraction contract",
          "A package-owned test suite independent of Memba test support",
          "Constructor validation, disconnected and connected binding, one owner subscription and relevant-only refresh",
          "Atomic result and interest replacement, access-error clearing and route rebind",
          "Duplicate and out-of-order notification behavior",
          "Bind and rebind window reconciliation, fresh mount/reconnect and owner-process subscriber cleanup",
          "No Memba or Commanded imports, dependencies, event vocabulary or authorization policy"
        ],
        "replaces": [
          "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
          "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-007b",
        "todo_line": "- [ ] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
        "origin": "Second bounded package-extraction slice of baseline task 007, reserved for adopting the package in the two accepted vertical consumers after the package API and independent tests exist.",
        "status": "pending",
        "coverage": [
          "Development path dependency sufficient for the web application to compile against the local package",
          "Dashboard and conversation-detail adoption of the package Query and Binding API",
          "Memba notification classification and authorized query loaders remaining application-owned",
          "Removal of superseded app-private generic modules and migrated generic test support",
          "Focused preservation of both accepted consumers' mount, rebind, refresh, transient-state and access-error behavior",
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
        "accepted_task_lines": [
          "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces."
        ],
        "pending_task_ids": [],
        "scope": "Accepted repository migration matrix, route inventory, event/interest map, fresh-authorization analysis, focused-proof inventory and explicit exclusions."
      },
      {
        "accepted_task_lines": [
          "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
        ],
        "pending_task_ids": [],
        "scope": "Accepted dashboard query/view-model boundary, fresh-authority prerequisite, coherent dashboard result assign, connected subscribe-before-read ordering and provisional predicates."
      },
      {
        "accepted_task_lines": [
          "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
        ],
        "pending_task_ids": [],
        "scope": "Accepted provisional generic lifecycle, opaque-interest matching, route rebind, bind-window reconciliation, access-error and reconnect contract."
      },
      {
        "accepted_task_lines": [
          "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
        ],
        "pending_task_ids": [],
        "scope": "Accepted dashboard binding, scoped Memba invalidation, partial-scope fallbacks and open-dashboard vertical behavior proof."
      },
      {
        "accepted_task_lines": [
          "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
        ],
        "pending_task_ids": [],
        "scope": "Accepted conversation-detail binding, multi-projector convergence, fresh-access proof, transient-state preservation and frozen extraction contract."
      },
      {
        "accepted_task_lines": [
          "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green."
        ],
        "pending_task_ids": [],
        "scope": "Accepted stakeholder scenario and real committed-membership-projector-to-already-open-member-LiveView proof."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-007a"
        ],
        "scope": "Standalone documented generic package extraction and package-owned lifecycle, matching, race, duplicate/out-of-order and cleanup tests."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-007b"
        ],
        "scope": "Adoption of the extracted package by the two accepted vertical consumers and removal of the provisional app-private generic contract."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008"
        ],
        "scope": "Complete remaining Memba notification adapter mappings and authorized queries."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009"
        ],
        "scope": "Migration of the five remaining in-scope member LiveViews."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-010"
        ],
        "scope": "Production package, Docker release and repository quality-gate integration."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011"
        ],
        "scope": "Remaining per-page proof, residual package lifecycle/race coverage and final exact-state validation."
      }
    ],
    "planner_note": "The trusted checkpoint and todo now preserve tasks 001, 003, 004, 005, 006 and 006A exactly as accepted, with no candidate origins. The latest independent review accepted task 006A, and the trusted after-stage recorded its sole agreed scenario green. Baseline task 007 was too broad for one reviewed worker visit, so its package extraction and consumer replacement obligations were split without loss: task 007A creates, documents and independently tests the package while leaving accepted consumers unchanged; task 007B will adopt that package in the dashboard and conversation detail and remove the provisional generic modules. The original task 007 line is recorded in both replacement lineages, while tasks 008 through 011 remain unchanged. Task 007A is explicit technical package work with no appropriate unimplemented acceptance scenario, so the packet uses package-focused proof and does not reactivate the already-green scenario or invent a conversation-detail scenario."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "1b40c6b59db1a8c2c22f4428946b014a06372766",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-007a-1b40c6b-package-extraction-1",
    "task_id": "task-007a",
    "todo_line": "- [ ] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "1b40c6b59db1a8c2c22f4428946b014a06372766",
    "outcome": "Create a standalone, documented local Mix package at `packages/live_query` containing the frozen generic live-query contract and a self-contained test suite that proves its lifecycle, matching, race and cleanup semantics without importing Memba or Commanded, while leaving the accepted application consumers unchanged for task 007B.",
    "scope": [
      "Create `packages/live_query` as an independently testable Mix application. Use application name `:live_query` and public `LiveQuery.Query`, `LiveQuery.Source` and `LiveQuery.Binding` modules unless an actual Mix/module collision is demonstrated.",
      "Extract the behavior of the provisional Query, Source and Binding modules into the package namespace, preserving their public callback shapes and return values rather than redesigning the accepted contract.",
      "Depend only on the minimum generic Phoenix LiveView boundary needed for socket ownership and assignment. Do not add Memba, Commanded, Ecto, PubSub projector vocabulary or application authorization dependencies.",
      "Document package purpose, public responsibilities, lifecycle ordering, opaque interest/invalidation contract, access-error ownership and non-goals in package README and module documentation.",
      "Create package-owned ExUnit support that does not use `MembaWeb.ConnCase`, `MembaWeb.Endpoint` or any other application test helper.",
      "Port the existing generic proofs for disconnected binding, connected subscribe-before-read, one shared owner subscription, relevant-only refresh, atomic result/interest replacement, route rebind, access-error clearing, bind-window reconciliation and fresh mount/reconnect.",
      "Add deterministic coverage for duplicate and out-of-order notifications, including proof that superseded interests do not refresh a query after successful replacement.",
      "Add deterministic rebind-window reconciliation coverage so a relevant notification delivered while new inputs and interests are being installed causes a fresh read of the new registration.",
      "Prove subscriber cleanup through owner-process termination using monitoring or an equivalent deterministic source-level observation. Preserve the frozen source contract; do not add an unsubscribe callback merely for the test.",
      "Keep the existing app-private generic modules and both accepted consumers intact during this packet. Task 007B owns application dependency wiring, namespace replacement and removal of superseded modules."
    ],
    "scope_exclusions": [
      "Do not edit `web/mix.exs`, `web/mix.lock`, the provisional modules under `web/lib/memba_web/live_query`, either accepted query or LiveView consumer, or existing web tests in this packet.",
      "Do not move `MembaWeb.LiveQuery.MembaReadModelSource` or any projector classification, event tuple, query loader, authorization rule or navigation policy into the package.",
      "Do not change the frozen loader result shape, source callback arities, one-result-assign rule, access-error return ownership or subscribe-before-read behavior.",
      "Do not add a process per query, shared result cache, durable notification log, SQL predicate inference, event-driven view-model patching or stream adapter.",
      "Do not broaden subscriber cleanup into a new explicit unsubscribe API unless the frozen contract is proven impossible; report that as unresolved instead of silently changing the API.",
      "Do not migrate dashboard or conversation-detail consumers, implement remaining adapter mappings or queries, migrate other member LiveViews, or alter staff streams.",
      "Do not edit Docker, release configuration, `bin/dev`, quality-gate scripts, acceptance features, ADRs, iteration plans or migration-matrix documentation.",
      "Do not reactivate or rerun the already-green Bob-sees-Alice scenario as packet validation, and do not invent another acceptance scenario for this technical extraction.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped repository suite; task 010 and the deterministic quality-gate stage own broad integration validation.",
      "Do not mark the todo line complete."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved scope requires a local path-dependency Mix application with an extractable generic core, its own tests and documentation. The package owns generic query loading, source callbacks, binding, matching, refresh and lifecycle behavior; Memba projection mapping, authorization and view-specific queries remain in the app. Required package proof includes interest replacement, duplicate/out-of-order notifications, cleanup, reconnect and bind-time races."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 007A is the first unchecked line. It is the package-only slice of former task 007; task 007B separately retains consumer replacement and provisional-module removal so this worker can leave accepted application behavior untouched."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint preserves tasks through 006A as accepted, records no required candidate origins and identifies the former task 007 package extraction as the next work. This packet is bound to current checkpoint HEAD rather than the baseline artifact's predecessor SHA."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted task 006A with no candidate origins after trusted evidence reached green. That accepted scenario work is not candidate provenance for task 007A and must not be reopened."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest worker result belongs to completed task 006A and changed only its scenario step-definition module. It reports no unresolved issue relevant to package extraction and provides no unaccepted candidate to carry into this packet."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The sole approved iteration scenario finished green with 180 tests and zero failures, and its @wip lifecycle was completed. Package extraction therefore has no appropriate red acceptance scenario to activate."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "This is the frozen semantic contract: stable query identity, one assign, one-argument loader, opaque interests, source subscribe/classify/matches callbacks, one LiveView owner and subscription, subscribe-before-read, bind-window reconciliation, atomic result/interest replacement, clearing on access errors and owner-controlled navigation."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture places reusable binding mechanics in a local Mix path dependency independent of Memba and Commanded while retaining Memba queries and notification mapping in the application."
      },
      {
        "path": "web/lib/memba_web/live_query/query.ex",
        "facts": "The provisional Query implementation validates an atom assign and one-argument loader, stores stable id/assign/load values and exposes the frozen `{:ok, result, interests}` or `{:error, reason}` read contract. Extract this behavior under the package namespace."
      },
      {
        "path": "web/lib/memba_web/live_query/source.ex",
        "facts": "The provisional Source implementation injects zero-argument subscribe, one-argument classify and two-argument matches callbacks. Interest and invalidation values are opaque; preserve these arities and generic semantics."
      },
      {
        "path": "web/lib/memba_web/live_query/binding.ex",
        "facts": "The accepted provisional binding already implements owner-held registrations, one shared source subscription, subscribe-before-read, result/interest replacement, rebind, relevant-only refresh, error clearing and mailbox-based bind-window reconciliation. This is the extraction source, not permission to change application consumers."
      },
      {
        "path": "web/test/memba_web/live_query/binding_test.exs",
        "facts": "Existing app-hosted tests are the executable semantic baseline for disconnected/connected bind, one subscription, matching refresh, interest replacement, rebind, access-error clearing, initial bind reconciliation and fresh connected mount. Port equivalent tests into package-owned support and add the missing duplicate/out-of-order, rebind-race and cleanup cases."
      },
      {
        "path": "web/test/support/live_query_fixture_live.ex",
        "facts": "The existing fixture demonstrates a real connected LiveView owner subscribing and rereading current state on a fresh mount. The package needs an application-independent equivalent rather than importing this MembaWeb fixture."
      },
      {
        "path": "web/mix.exs",
        "facts": "The repository currently has only the web Mix application and no local live-query dependency. Its Phoenix LiveView version gives the compatibility boundary for the package, but this file remains unchanged until consumer adoption/integration work."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "This module contains Memba projector modules, event classification, fallback scope rules and PubSub subscription details. It must remain application-owned and must not be copied into package source or tests."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Tests must use supervised processes where applicable, deterministic process synchronization and monitoring, and must avoid `Process.sleep/1` and `Process.alive?/1`. These rules apply to package race and cleanup proofs."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView tests should exercise observable owner behavior with deterministic synchronization. The generic package may use minimal package-local LiveView test support, but it must not depend on the Memba endpoint or application UI."
      }
    ],
    "constraints": [
      "Treat the types, callback arities, result shapes and lifecycle semantics in `extraction-contract.md` as frozen.",
      "Use `packages/live_query` consistently so the subsequent consumer and Docker tasks have one stable local path.",
      "Keep package source and tests free of `Memba` and `Commanded` module references and free of Memba event or projector vocabulary.",
      "Keep interests and invalidations opaque terms; only the injected source decides matching.",
      "A successful read must replace the coherent result and complete interest set together; a failed initial read, rebind or refresh must clear the public result and interests before returning the error.",
      "A connected first bind must subscribe before reading, and multiple registrations using the same source must not create one subscription per query.",
      "Reconciliation tests must record ordering before triggering notifications and use deterministic mailbox/process synchronization.",
      "Duplicate and out-of-order tests must assert read counts or equivalent observable outcomes, not merely that calls return without crashing.",
      "Subscriber cleanup must follow LiveView/owner process lifetime and must not introduce a dedicated query process or change the source interface.",
      "Package documentation must distinguish generic mechanism from application authorization, projector mapping, access transitions and navigation policy.",
      "Do not claim task 007B consumer adoption or task 010 production/quality-gate integration as completed evidence.",
      "Return any unavoidable namespace, dependency or lifecycle-contract conflict as an unresolved issue instead of editing the approved plan or app-owned policy."
    ],
    "focused_validation": [
      "(cd packages/live_query && MIX_ENV=test mix compile --warnings-as-errors)",
      "(cd packages/live_query && mix test)",
      "(cd packages/live_query && mix format --check-formatted)",
      "(cd packages/live_query && mix deps.tree)",
      "if grep -R -n -E '\\b(Memba|Commanded)\\b' packages/live_query/lib packages/live_query/test; then exit 1; else exit 0; fi",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and identify the package application name, package directory and public module namespace.",
      "Describe the package dependency graph and confirm that neither Memba nor Commanded is a direct or transitive application-specific dependency.",
      "Map each frozen Query, Source and Binding responsibility to its extracted package module and confirm callback arities and return shapes were preserved.",
      "Provide a test matrix covering construction validation, disconnected binding, subscribe-before-read, one owner subscription, relevant and unrelated invalidations, atomic result/interest replacement, access-error clearing and route rebind.",
      "Identify the exact package tests proving duplicate and out-of-order notifications do not refresh from superseded interests, including the observable read-count evidence.",
      "Explain how bind-window and rebind-window notifications are delivered and reconciled deterministically, including the asserted operation order.",
      "Explain the reconnect proof and the subscriber-cleanup proof, including how owner termination is observed without `Process.sleep/1`, `Process.alive?/1`, a new query process or an unsubscribe callback.",
      "Summarize the package README/module documentation, especially application-owned responsibilities and explicit non-goals.",
      "Confirm package source and tests contain no Memba/Commanded modules, projector/event vocabulary or authorization policy.",
      "Confirm `web/`, Docker, release files, quality-gate scripts, acceptance features, ADRs and the approved plan were not changed, and that the provisional consumers remain functional and untouched for task 007B.",
      "Report every focused validation command, exit status and concise evidence.",
      "Report any unresolved API, dependency, race or cleanup issue instead of weakening the frozen contract or broadening this packet."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}