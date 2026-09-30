{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ba89b32856e526b0399e905c04ce787dc8fffc47",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally."
    ],
    "pending_obligations": [
      {
        "candidate_origins": [],
        "coverage": [
          "App-private provisional query, source and binding responsibilities",
          "Opaque interest matching and replacement",
          "One public result assign per registered query",
          "Route rebind behavior",
          "Relevant notification refresh and access-error surfacing",
          "Connected subscribe-before-read ordering and bind-window reconciliation",
          "Fresh static mount, connected mount and reconnect behavior",
          "LiveView-owned state without a process per query"
        ],
        "origin": "Technical lifecycle slice split from approved plan tasks 2 and 3 so race and reconnect behavior can be proved independently before either vertical consumer freezes the package API.",
        "replaces": [
          "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
          "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
        ],
        "status": "prepared",
        "task_id": "task-004",
        "todo_line": "- [ ] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Dashboard registration through the provisional binding",
          "Scoped dashboard collection and identity interests",
          "Club-member and selected-group entry and exit",
          "Member ordering and derived counts",
          "Represented Person and role-label refresh",
          "Fresh route and access transitions",
          "Unrelated-club and unrelated-query isolation",
          "Transient dashboard state preservation"
        ],
        "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the provisional lifecycle contract before public API freeze.",
        "replaces": [
          "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "status": "pending",
        "task_id": "task-005",
        "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "One coherent conversation-detail result assign",
          "Conversation-message collection and represented-author interests",
          "Exact follow identity",
          "Member delivery status and staff delivery reason contributors",
          "Independent projector commit-order convergence",
          "Fresh membership, group and conversation authorization",
          "Unrelated conversation, message, delivery, club and Person isolation",
          "Reply and disclosure state preservation",
          "Generic contract freeze only after both vertical proofs"
        ],
        "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
        "replaces": [
          "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "status": "pending",
        "task_id": "task-006",
        "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Extractable local Mix application",
          "Replacement of app-private binding use in dashboard and conversation detail",
          "Generic query registration, interest replacement, matching and refresh",
          "Duplicate and out-of-order notification behavior",
          "Subscriber cleanup and lifecycle tests",
          "No Memba or Commanded imports in package source or tests"
        ],
        "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
        "replaces": [
          "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
        ],
        "status": "pending",
        "task_id": "task-007",
        "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Every projector/event mapping recorded in the accepted migration matrix",
          "Collection, identity and authorization interests",
          "Old and new scopes where available",
          "Conservative club, family or global fallbacks when exact scope is unavailable",
          "Remaining fresh authorized view-specific queries",
          "No app-specific policy in the generic package"
        ],
        "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
        "replaces": [
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "status": "pending",
        "task_id": "task-008",
        "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Group creation, settings, message composition, delivery detail and invitation LiveViews",
          "One coherent result assign per remaining in-scope page",
          "Preserved routes, access transitions, forms, commands, navigation and UI",
          "Live delivery status and staff reason convergence",
          "Existing conversation and delivery behavior",
          "No staff stream migration"
        ],
        "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
        "replaces": [
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "status": "pending",
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Supported path dependency in web/mix.exs",
          "Docker dependency-copy and compilation ordering",
          "Production release inclusion",
          "Explicit package test execution in the repository quality gate",
          "Supported local and CI environments"
        ],
        "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
        "replaces": [
          "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
        ],
        "status": "pending",
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Stakeholder-readable club-member live-update example",
          "Focused regression proof for every migrated member page",
          "At least one real committed-projector-to-open-LiveView path",
          "Remaining package mount, change, reconnect and race coverage",
          "Final full dev check on the exact delivered state"
        ],
        "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
        "replaces": [
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "status": "pending",
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`."
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
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-004"
        ],
        "scope": "Provisional generic lifecycle, opaque-interest and bind-window contract."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-005"
        ],
        "scope": "Dashboard binding, scoped invalidation and vertical behavior proof."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-006"
        ],
        "scope": "Conversation-detail binding, multi-projector/access proof and API freeze."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-007"
        ],
        "scope": "Frozen generic local package extraction and hardening."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008"
        ],
        "scope": "Complete Memba notification adapter and remaining authorized queries."
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
        "scope": "Production package, Docker release and quality-gate integration."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011"
        ],
        "scope": "Acceptance example, remaining focused proof and final exact-state validation."
      }
    ],
    "planner_note": "The accepted review for task 003 is reflected by preserving its exact checked todo line and removing its now-accepted candidate provenance from pending work. Task 004 is the first unchecked obligation and is prepared without further splitting or reordering. It remains an app-private, provisional lifecycle slice: dashboard wiring and Memba projector translation stay in task 005, conversation proof and API freeze stay in task 006, and package extraction remains task 007. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ba89b32856e526b0399e905c04ce787dc8fffc47",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-004-ba89b32-provisional-binding-1",
    "task_id": "task-004",
    "todo_line": "- [ ] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ba89b32856e526b0399e905c04ce787dc8fffc47",
    "outcome": "Establish and focused-test an app-private provisional LiveView-owned query binding and source contract that installs one result assign per query, keeps interests opaque, refreshes only relevant registrations, safely rebinds route inputs, surfaces access errors, reconciles notifications delivered across the connected bind window, and rereads fresh state on LiveView remount/reconnect without introducing per-query processes or freezing the eventual package API.",
    "scope": [
      "Add app-private provisional modules, under a cohesive `MembaWeb.LiveQuery` namespace or an equivalently narrow location, that separate query loading, source subscription/notification classification and socket-owned binding state. Keep names and callback shapes explicitly provisional.",
      "Represent each registration with a stable query identity, one public result assign, current query inputs or read callback, and current opaque interests. Internal registry metadata may occupy one reserved socket assign, but projection fields must not be mirrored into additional public compatibility assigns.",
      "Support a query success carrying one coherent result plus replacement interests and an explicit access-error result such as `:forbidden` or `:not_found`. Return access errors to the owning LiveView without embedding redirect, navigation, exception or Memba authorization policy in the binding.",
      "On the disconnected HTTP mount, read current query state without subscribing. On the connected mount, subscribe before the initial read, then install the result and interests. A recognized notification delivered after subscription while the initial synchronous read or interest installation is in progress must cause conservative reconciliation rather than being lost.",
      "Handle source notifications in the LiveView process: translate or classify through the injected source contract, match opaque invalidations against current interests, reread only affected registrations, and replace each successful result and its interests together while preserving unrelated result assigns and transient socket assigns.",
      "Support route rebind for an existing query identity so changed inputs produce a fresh result and interests, old interests stop matching, and subsequent refreshes use the rebound inputs.",
      "Model reconnect according to Phoenix lifecycle semantics: a new connected LiveView process remounts, subscribes again and performs a fresh read. Do not add an in-process reconnect callback that Phoenix does not invoke.",
      "Add deterministic focused tests using a fake query/source and, where needed, a minimal LiveView fixture. Cover disconnected read without subscription, connected subscribe-before-read ordering, one result assign per query, unrelated-assign preservation, at least two registrations for relevant/unrelated refresh, interest replacement, route rebind, initial/rebind/refresh access errors, bind-window reconciliation, fresh remount/reconnect reads and execution in the owning process."
    ],
    "scope_exclusions": [
      "Do not wire the provisional binding into `MembaWeb.MemberDashboardLive` or alter the accepted dashboard query, presentation, templates, routes or focused dashboard tests; task 005 owns dashboard integration.",
      "Do not implement the concrete `Memba.ReadModelChanges` source adapter, projector/event-to-interest mappings, collection or identity key vocabulary, old/new-scope handling or conservative Memba fallbacks; tasks 005 and 008 own those.",
      "Do not create or migrate conversation detail, delivery detail or another member LiveView query; tasks 006, 008 and 009 retain those obligations.",
      "Do not create the local Mix package, declare a public or frozen API, add a path dependency, or change Docker, release or quality-gate integration.",
      "Do not add a GenServer, supervisor, global cache, process per query, durable notification log, projector replay or event-driven view-model field patching.",
      "Do not expand this slice into duplicate/out-of-order optimization or an explicit subscriber-cleanup API reserved for package hardening in task 007; ordinary PubSub process-exit cleanup is sufficient for the provisional proof.",
      "Do not claim recovery for broadcasts lost before subscription or while an uninterrupted process is disconnected; bind-window reconciliation covers notifications delivered after subscription, and a remount performs a fresh read.",
      "Do not edit acceptance features, ADRs, the migration matrix, the approved plan, todo file, staff stream-backed views or other out-of-scope surfaces."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The technical model assigns three responsibilities: a query returns one view model plus interests or an access error, a source subscribes and converts notifications to invalidations, and a LiveView-owned binding installs one assign, matches notifications, refreshes and replaces result plus interests. Connected binding subscribes before reading, bind-window notifications require conservative reconciliation, access transitions remain owned by the LiveView, and no process per query is allowed."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 004 is the first unchecked line and is limited to an app-private provisional binding/source lifecycle contract. Task 005 separately owns dashboard wiring and scoped Memba translation, task 006 owns conversation proof and API freeze, and task 007 owns package extraction and hardening."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The accepted matrix requires connected subscribe-before-read, conservative reconciliation for notifications arriving during first result/interest installation, fresh reads on mount and reconnect, opaque logical interests rather than frozen types, and no durable PubSub guarantee. Its dashboard-specific projector mappings and vertical proof gaps are later-task scope."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted decision requires one coherent view model per ordinary assign, LiveView-owned subscriptions, relevant changes causing fresh authorized reads, Memba policy remaining outside the generic mechanism, and staff streams remaining deferred."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "The existing source broadcasts post-commit `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` messages through application PubSub. Task 004 needs an injectable source boundary around this role, not concrete projector translation."
      },
      {
        "path": "web/lib/memba_web/live/member_dashboard_live.ex",
        "facts": "The accepted dashboard currently subscribes during connected mount before calling its query, stores projection-backed output under `:dashboard`, derives only shell `:page_title`, and retains hand-written `handle_info/2` predicates. This task must leave that consumer unchanged while proving the reusable provisional lifecycle in isolation."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The accepted app-owned query demonstrates the required read boundary: stable route inputs plus authenticated email produce either one coherent result or `{:error, :forbidden | :not_found}`, with active-club authority reread on each call. The provisional contract must support this shape without importing dashboard policy."
      },
      {
        "path": "web/lib/memba/read_model_changes.ex",
        "facts": "The current publisher exposes one shared PubSub topic and post-commit message shape. The provisional source abstraction may be tested with a fake source; concrete Memba notification-to-interest translation remains outside task 004."
      },
      {
        "path": "docs/tools/phoenix-live-view/guides/server/live-navigation.md",
        "facts": "`handle_params/3` runs after mount and on live patches, so route-dependent registrations need an explicit rebind path that replaces prior inputs and interests rather than accumulating them."
      },
      {
        "path": "docs/tools/phoenix-live-view/guides/server/error-handling.md",
        "facts": "Phoenix performs an HTTP mount followed by a connected mount, and after a connected process failure it remounts a new stateful LiveView process. Reconnect proof should therefore demonstrate fresh remount/read behavior instead of inventing an in-process reconnect callback."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView state changes belong in socket assigns, tests should assert behavior through framework APIs, and transient UI state must not be disturbed by replacing a query result."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests must avoid `Process.sleep/1`; deterministic message ordering or synchronization should be used. Test-only processes, if any, must be started with `start_supervised!/1`, and separate modules should not be nested in one source file."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The latest review accepted task 003, including the fresh query boundary, coherent dashboard result, connected subscribe-before-read ordering and preserved provisional predicates. It explicitly leaves lifecycle, scoped invalidation and conversation proofs in tasks 004 onward; there is no rejected task-004 candidate to revise."
      }
    ],
    "constraints": [
      "Keep all new contract code app-private and provisional; do not extract it or present its names and callback signatures as the frozen package API.",
      "Keep query execution, subscription state, notification handling and refreshes in the owning LiveView process.",
      "Treat interests and invalidations as opaque values interpreted through injected matching behavior; the binding must not know Memba projectors, Commanded events, SQL predicates or authorization policy.",
      "Subscribe only for a connected stateful mount and establish that subscription before its initial query read.",
      "Conservatively reconcile a recognized notification delivered during the subscribe/read/install window, using deterministic synchronization and without relying on timing sleeps.",
      "Replace a successful query result and its interests together; do not patch fields from notifications and do not overwrite unrelated query results or transient assigns.",
      "After route rebind, old inputs and interests must no longer drive matching or refresh.",
      "Surface access errors to the owning LiveView and do not encode redirect, raise, flash or private-surface policy in the provisional layer.",
      "Reconnect means a new connected mount/process with a new subscription and fresh read; do not promise recovery of PubSub messages lost before that subscription.",
      "Do not use `Process.sleep/1` in tests and do not mark the todo line complete; return implementation and focused validation evidence for review."
    ],
    "focused_validation": [
      "bin/dev test test/memba_web/live_query",
      "bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and state the responsibility of each provisional query, source, binding or test-support module.",
      "Document the implemented success and access-error shapes and the responsibility split between query, source, binding and owning LiveView.",
      "Identify focused tests proving disconnected read without subscription, connected subscribe-before-read ordering, one result assign per query, unrelated-assign preservation, relevant versus unrelated refresh, interest replacement and route rebind.",
      "Provide a deterministic bind-window ordering trace showing subscription, initial read in progress, notification delivery, result/interest installation and conservative follow-up read.",
      "Show that successful refresh replaces only the affected result and interests, while another registered query and transient assigns remain unchanged.",
      "Show that route rebind stops old interests from causing refresh and that later refresh uses the new query inputs.",
      "Show that initial-read, rebind and refresh access errors are surfaced to the owner without generic navigation policy or silent retention as a successful result.",
      "Show that reconnect is tested as a fresh connected mount/process that subscribes again and rereads changed state.",
      "Confirm that no per-query process, Memba projector mapping, Commanded dependency, package extraction or dashboard wiring was introduced.",
      "Report each focused validation command with exit status and concise pass evidence, plus any unresolved issue; bind-window reconciliation or reconnect gaps must remain unresolved rather than being treated as complete."
    ],
    "candidate_origins": []
  }
}