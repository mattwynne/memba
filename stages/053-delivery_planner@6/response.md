{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API."
    ],
    "pending_obligations": [
      {
        "task_id": "task-005",
        "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
        "status": "prepared",
        "origin": "Dashboard vertical proof split from approved plan tasks 2, 4 and 5, using the accepted provisional lifecycle contract before public API freeze.",
        "replaces": [
          "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "coverage": [
          "Dashboard registration through the provisional binding",
          "Dashboard-specific Memba ReadModelChanges subscription and translation",
          "Scoped dashboard collection, identity and authorization interests",
          "Club-member and selected-group member entry and exit",
          "Member ordering and derived counts",
          "Represented Person and role-label refresh",
          "Current-actor role, route and access transitions using fresh authority",
          "Message and conversation-access invalidation required by the existing dashboard model",
          "Unrelated-club and unrelated-notification isolation",
          "Transient dashboard state preservation"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-006",
        "todo_line": "- [ ] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
        "status": "pending",
        "origin": "Conversation-detail vertical proof and API-freeze gate split from approved plan tasks 2, 4, 5 and 7. It follows the dashboard proof so the generic contract is justified by two materially different consumers.",
        "replaces": [
          "- [ ] 003 Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
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
        "candidate_origins": []
      },
      {
        "task_id": "task-007",
        "todo_line": "- [ ] 007 Extract, implement and test the frozen generic contract as a local Mix package, replace the two provisional consumers with it, and cover interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, subscriber cleanup and lifecycle without Memba or Commanded imports.",
        "status": "pending",
        "origin": "Remaining generic-package implementation from approved plan task 3, reordered after the two pre-freeze vertical proofs required by the approved technical model.",
        "replaces": [
          "- [ ] 004 Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports."
        ],
        "coverage": [
          "Extractable local Mix application",
          "Replacement of app-private binding use in dashboard and conversation detail",
          "Generic query registration, interest replacement, matching and refresh",
          "Duplicate and out-of-order notification behavior",
          "Subscriber cleanup and lifecycle tests",
          "No Memba or Commanded imports in package source or tests"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008",
        "todo_line": "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
        "status": "pending",
        "origin": "Remaining application-adapter and query work from approved plan task 4 after the dashboard and conversation proof mappings are implemented.",
        "replaces": [
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "Every projector/event mapping recorded in the accepted migration matrix",
          "Collection, identity and authorization interests",
          "Old and new scopes where available",
          "Conservative club, family or global fallbacks when exact scope is unavailable",
          "Remaining fresh authorized view-specific queries",
          "No app-specific policy in the generic package"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
        "status": "pending",
        "origin": "Remaining migration work from approved plan task 5 after dashboard and conversation detail serve as the pre-freeze proof consumers.",
        "replaces": [
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "coverage": [
          "Group creation, settings, message composition, delivery detail and invitation LiveViews",
          "One coherent result assign per remaining in-scope page",
          "Preserved routes, access transitions, forms, commands, navigation and UI",
          "Live delivery status and staff reason convergence",
          "Existing conversation and delivery behavior",
          "No staff stream migration"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
        "status": "pending",
        "origin": "Approved plan task 6, retained after minimum development-time package consumption and separated from production release and quality-gate completion.",
        "replaces": [
          "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
        ],
        "coverage": [
          "Supported path dependency in web/mix.exs",
          "Docker dependency-copy and compilation ordering",
          "Production release inclusion",
          "Explicit package test execution in the repository quality gate",
          "Supported local and CI environments"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Add the focused acceptance example, close the focused proof gaps for every migrated member page and a real committed-projector-to-open-LiveView path, complete package lifecycle/race coverage, and run final `dev check`.",
        "status": "pending",
        "origin": "Approved plan task 7 retained as the final acceptance, proof-gap and exact-state validation obligation after implementation slices complete.",
        "replaces": [
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`."
        ],
        "coverage": [
          "Stakeholder-readable club-member live-update example",
          "Focused regression proof for every migrated member page",
          "At least one real committed-projector-to-open-LiveView path",
          "Remaining package mount, change, reconnect and race coverage",
          "Final full dev check on the exact delivered state"
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
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-005"
        ],
        "scope": "Dashboard binding, dashboard-scoped Memba invalidation and vertical behavior proof."
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
    "planner_note": "The accepted review for task 004 is reflected by preserving its exact checked todo line and removing that completed obligation from pending work. Task 005 is now the first unchecked line and is prepared as the dashboard vertical proof without further splitting or reordering. The accepted provisional Binding, Query and Source modules supply the lifecycle prerequisite; this packet adds only dashboard-specific query interests, Memba notification translation and consumer proof. Conversation detail and API freeze remain task 006, package extraction remains task 007, full adapter completion remains task 008, and the acceptance feature plus full dev check remain task 011. No todo line was edited during this planner visit, and there is no unaccepted candidate origin to preserve."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-005-bcf5640-dashboard-binding-1",
    "task_id": "task-005",
    "todo_line": "- [ ] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "bcf5640aff475789689ea98bf513c4ce5097a274",
    "outcome": "Make the existing member dashboard a real consumer of the provisional LiveView-owned query binding: one fresh-authorized dashboard result and its replacement interests must drive scoped refreshes from committed Memba projection notifications, while unrelated changes are ignored and route, access and transient UI behavior remain intact.",
    "scope": [
      "Add an app-private, explicitly provisional Memba ReadModelChanges source adapter that subscribes to the shared PubSub topic, classifies dashboard-relevant projector notifications into opaque invalidations, and performs scoped interest matching without moving Memba knowledge into the generic Binding or Source modules.",
      "Adapt `MembaWeb.MemberDashboardQuery` to provide a provisional query descriptor or loader returning the existing coherent dashboard view model plus replacement interests. Preserve `load/3` as the fresh-authority boundary, or retain an equivalent directly tested public contract, so every bind, rebind and notification refresh normalizes the authenticated email and rereads active-club authority.",
      "Register only one dashboard live query under the existing `:dashboard` assign. Do not recreate separate projection-backed compatibility assigns; internal binding metadata and shell-derived `:page_title` are not additional query results.",
      "Register dashboard collection interests for selected-club members, discoverable groups, current-person participating groups, selected-group members, selected-group conversations and represented-membership role assignments so rows absent from the old result can enter and existing rows can leave.",
      "Register exact or represented interests for the selected Club and Group, current membership and Person, represented member and conversation participant Persons, represented groups, conversations/messages, selected-group access, current-actor permissions and role data. Keep current-actor authorization interests distinct from represented-member badge interests.",
      "Translate dashboard-relevant Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess projector notifications according to the accepted migration matrix. Scope known club, group, person, membership and conversation identities; use the documented family, club or global conservative fallback when required scope is unavailable instead of silently ignoring a potentially relevant event.",
      "For `MessageSent`, emit exact or derived conversation invalidations and a conservative club-conversation invalidation because the event does not contain its audience group. Preserve existing dashboard conversation and reply convergence while removing the current unscoped MemberEmailDelivery refresh, since the dashboard no longer displays delivery data.",
      "Replace the dashboard's manual PubSub subscription and hand-written projector predicates with `Binding.bind/4` during mount, `Binding.rebind/3` for route-dependent selected-group changes and explicit command-driven rereads, and `Binding.handle_notification/2` for source messages. Connected bind must subscribe before reading; disconnected mount must read without subscribing.",
      "After each successful bind, rebind or notification refresh, synchronize only LiveView-owned shell or route coordination derived from the new dashboard, including `:page_title` and targeted-member resolution where applicable. Keep active section, picker state/query/form, admission and removal operation state, access-request state, targeted success/focus, flash and navigation outside the query result.",
      "Map dashboard binding errors back to the LiveView's existing `:forbidden` and `:not_found` owner policy. A failed refresh must not retain private dashboard data or teach the generic binding about redirects, exceptions or Memba authorization.",
      "Add focused source/query tests for interest construction, classification, matching, missing-scope fallbacks and unrelated-club isolation. Keep the interest representation app-private and provisional; this task must not claim a frozen package vocabulary.",
      "Add focused LiveView proof that club members and selected-group members enter and leave already-open lists, counts and name ordering converge, represented Person invalidation rereads only matching dashboards, represented role assignment/removal and role-definition changes update badges, current-actor role or membership loss rechecks authority, and route patches replace old selected-group interests.",
      "Retain and extend proof that relevant dashboard replacement preserves transient picker and command state, that unrelated club/person/group notifications do not expose deliberately changed projection data, and that existing admission, targeted-add, conversation-access and route behavior still works through the binding."
    ],
    "scope_exclusions": [
      "Do not migrate conversation detail, delivery detail, settings, message composition, group creation, invitations or any staff, public or auth surface; tasks 006, 008 and 009 retain those obligations.",
      "Do not freeze the provisional API or interest vocabulary. Conversation detail must provide the second materially different vertical proof before task 006 freezes the contract.",
      "Do not extract a local Mix package, add a path dependency, or change Docker, release or quality-gate integration; tasks 007 and 010 own those changes.",
      "Do not complete projector mappings needed only by non-dashboard consumers or implement delivery-row lookup fallbacks for conversation and delivery detail; task 008 retains the complete adapter obligation.",
      "Do not add or change domain events, aggregates, commands, projector writes, projection schemas, migrations, authorization policy or read-model persistence just to drive invalidation.",
      "Do not introduce `PersonRenamed`, name editing or profile-photo behavior. Prove the dashboard's exact represented-Person invalidation with existing Person projector envelopes and controlled projection state; iterations 068 and 069 remain out of scope.",
      "Do not require exact represented role IDs if the dashboard result does not expose them. Exact membership role-assignment interests plus the accepted conservative club role/permission invalidation are sufficient for this provisional slice.",
      "Do not retain the broad MemberEmailDelivery dashboard handler as compatibility behavior; delivery state is not part of the accepted dashboard result.",
      "Do not add a GenServer, process per query, global cache, durable notification log, projector replay, event-driven field patching or a claim that PubSub is durable.",
      "Do not edit the approved plan, todo line, migration matrix, ADRs, acceptance feature or design sources, and do not mark task 005 complete."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires one authorized dashboard query under one assign, collection interests for absent-row entry and exit, represented identity interests, fresh authorization on every refresh, subscribe-before-read, bind-window reconciliation and rereading rather than patching fields from events. Dashboard and conversation detail must prove the provisional contract before API freeze."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 005 is the first unchecked obligation. It owns dashboard wiring and proof; task 006 retains conversation detail and API freeze, task 007 retains package extraction, task 008 retains complete adapter coverage, and task 011 retains the acceptance feature and final full gate."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The accepted dashboard matrix identifies selected-club members, discoverable and participating groups, selected-group members and conversations, represented Persons and role assignments, current permissions and access as dependencies. Its projector table defines scoped Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess mappings, including conservative fallbacks and the remaining dashboard proof gaps."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted decision requires each view-specific query to return one coherent view model for one assign, with the LiveView owning subscription and relevant committed changes triggering a fresh authorized read. Memba concerns remain outside the generic mechanism, and staff streams are deferred."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Committed projector updates are published as `{:read_model_changed, %{projector: ..., source_event: ..., metadata: ..., changes: ...}}` on the shared application PubSub topic after projection transactions commit."
      },
      {
        "path": "web/lib/memba_web/live_query/binding.ex",
        "facts": "The accepted provisional binding already supports disconnected reads, connected subscription before the initial read, one shared source, bind-window reconciliation, relevant-only refresh, replacement interests, route rebind and owner-visible access errors while keeping state in the LiveView process. Dashboard integration should consume this behavior rather than create a second lifecycle."
      },
      {
        "path": "web/lib/memba_web/live_query/query.ex",
        "facts": "A provisional query has a stable identity, one public assign and a one-argument loader returning either one result plus opaque interests or an access error. Its callback shape remains app-private until both vertical proofs are complete."
      },
      {
        "path": "web/lib/memba_web/live_query/source.ex",
        "facts": "The provisional source separates subscription, raw-notification classification and opaque interest matching. It deliberately contains no Memba projector mapping, so dashboard-specific translation belongs in an injected app adapter."
      },
      {
        "path": "web/lib/memba_web/live/member_dashboard_live.ex",
        "facts": "The accepted dashboard already stores projection-backed output only in `:dashboard` and derives `:page_title`, but it still manually subscribes, broadly refreshes for every MemberEmailDelivery change and handles only a same-club projector allowlist. `handle_params/3` and command paths call the old direct refresh helper, while picker, targeted-member, operation and access-request assigns remain LiveView-owned."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "The accepted query starts from routed club ID, authenticated email and selected group ID; every call normalizes the email, rereads active clubs and delegates to the established presentation boundary, preserving `:forbidden` and `:not_found` distinctions."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_presentation.ex",
        "facts": "The coherent dashboard result composes club members, discoverable and participating groups, current authorization, selected-group members, conversations, represented names and role labels. Conversation rows include reply-derived data but deliberately omit delivery glance fields, so MemberEmailDelivery is no longer a dashboard dependency."
      },
      {
        "path": "web/lib/memba/read_model_changes.ex",
        "facts": "The existing publisher exposes the single shared topic and ADR-defined post-commit envelope. The dashboard adapter should subscribe through this API; no publisher or projector write change is required."
      },
      {
        "path": "web/lib/memba/membership/projectors/person.ex",
        "facts": "Current Person projector notifications cover creation and email-address changes and carry Person identity but no club scope. Task 005 must match represented Person identities without inventing a club or introducing the out-of-scope PersonRenamed event."
      },
      {
        "path": "web/lib/memba/membership/projectors/role.ex",
        "facts": "Role projection handles role definitions, permissions, exact assignments/removals and membership-removal compatibility events. Exact assignment events carry club, membership, person and role IDs, while compatibility removals may require conservative membership, club-permission or global family invalidation."
      },
      {
        "path": "web/lib/memba/messaging/projectors/message.ex",
        "facts": "MessageSent projects roots and replies using a derivable conversation ID. The event carries club and conversation/message identity but no audience group, requiring a conservative club-conversation invalidation for dashboard collection entry and reply-derived changes."
      },
      {
        "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
        "facts": "Existing tests establish the sole `:dashboard` result assign, group discovery refresh, selected-group access loss, current-actor role loss, conversation-access removal, route rechecks and picker-state preservation. Missing proof includes club-member entry/exit and ordering, represented Person isolation, live represented-member badge changes and old-interest replacement after route patches."
      },
      {
        "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
        "facts": "This suite protects the strongest existing real command/projector-to-open-dashboard group-admission behavior and command-owned state. It should remain passing while the manual handler is replaced by the provisional binding."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView state changes belong in socket assigns and behavioral tests should use framework APIs. Query refresh must replace the dashboard assign without disturbing transient form, picker or navigation state."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests must avoid `Process.sleep/1`, use deterministic synchronization, and start test processes with `start_supervised!/1` where applicable."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The task-004 worker reported the provisional Query, Source and Binding implementation with seven focused tests passing, including relevant-only refresh, interest replacement, route rebind, access errors, bind-window reconciliation and fresh connected remounts. It explicitly left dashboard wiring and Memba mapping for task 005."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The latest review accepted task 004 and confirmed that dashboard wiring, scoped Memba translation and vertical behavior proof remain later work. There is no rejected task-005 candidate to revise, so this packet is a fresh implementation attempt."
      }
    ],
    "constraints": [
      "Keep all dashboard interest and invalidation types app-private and provisional; do not present names or tuple shapes as the frozen package API.",
      "Keep the dashboard query result coherent under only `:dashboard`; do not mirror projection fields into separate public socket assigns.",
      "Continue to execute reads, subscription handling and refreshes in the owning LiveView process.",
      "Use the accepted provisional Binding, Query and Source responsibilities. Change their generic behavior only if dashboard integration reveals a concrete contract defect, and document that defect and its focused regression proof.",
      "Subscribe only during connected binding and before the initial connected read. Preserve disconnected initial rendering without a PubSub subscription.",
      "On every bind, route rebind and relevant notification, use the authenticated email to reread current active-club and page-specific authority; never authorize from `current_identity_clubs` captured at mount.",
      "Replace successful dashboard result and interests together. Do not patch dashboard fields from source events or retain old interests after route rebind.",
      "Scope notifications using carried IDs whenever available. Unknown or legacy dashboard-relevant events must use the matrix's conservative family, club or global fallback rather than being silently ignored.",
      "Keep represented-member role-label invalidation distinct from current-actor permission invalidation, even when one Role event produces both invalidations.",
      "Treat MessageSent roots and replies as dashboard dependencies, but do not restore delivery-status interests or the old all-deliveries refresh.",
      "Preserve existing forbidden versus not-found owner behavior and clear private query data on an access error before leaving or raising from the private surface.",
      "Preserve route state, targeted-member coordination, picker/form contents, command operation state, flash and navigation across successful query refreshes.",
      "Do not use `Process.sleep/1` in tests, do not run an unscoped full-suite command as focused validation, and do not mark the todo line complete."
    ],
    "focused_validation": [
      "bin/dev test test/memba_web/live_query test/memba_web/member_dashboard_query_test.exs",
      "bin/dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_dashboard_targeted_add_live_test.exs",
      "bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and state whether it implements dashboard query interests, Memba source translation, LiveView integration or focused proof.",
      "Document the final provisional dashboard query input, success and access-error shapes and show that fresh active-club authority is reread for bind, rebind and notification refresh.",
      "Enumerate the dashboard collection, represented identity and authorization interests produced from a successful result, including absent-row entry scopes and replacement after a selected-group route change.",
      "Provide a projector/event-to-invalidation summary for Club, Membership, Person, Group, GroupMembership, Role, Message and ConversationGroupAccess, including the conservative behavior used when exact scope is missing.",
      "Show that the dashboard no longer manually subscribes or uses its old projector allowlist and broad MemberEmailDelivery handler, and that its notifications flow through the provisional binding.",
      "Identify focused tests proving club-member entry/removal, selected-group member entry/removal, member ordering and derived count updates in an already-open dashboard.",
      "Identify focused tests proving exact represented-Person matching and isolation without introducing PersonRenamed or another out-of-scope domain event.",
      "Identify focused tests proving represented-member role badge assignment/removal or role-definition refresh independently from current-actor permission and access transitions.",
      "Show that route patching replaces old selected-group interests, preserves not-found semantics and prevents an old-group-only notification from refreshing the rebound dashboard.",
      "Show that selected-club membership, current-actor role or selected-group participation loss performs a fresh authorized read and does not retain private rows.",
      "Show unrelated-club and unrelated-Person/group notifications are ignored through the real source matching path rather than merely by a hand-written LiveView clause.",
      "Show a relevant dashboard replacement preserves picker/query state and the existing admission, targeted-add, operation, access-request, active-section, flash and navigation behavior.",
      "Confirm that no conversation-detail migration, API freeze, package extraction, complete cross-surface adapter, domain event, projector write, acceptance feature or staff-stream change was introduced.",
      "Report every focused validation command with exit status and concise pass evidence, plus any unresolved issue; missing entry/exit, role, access, route-isolation or transient-state proof must remain unresolved rather than being treated as complete."
    ],
    "candidate_origins": []
  }
}