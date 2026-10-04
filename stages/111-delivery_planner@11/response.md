{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "de561b643279f7a58ade8f3ae8198becae25da83",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
      "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
      "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
      "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
      "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
      "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
      "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
      "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
      "- [x] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
      "- [x] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
      "- [x] 009A Migrate `MembaWeb.MemberGroupLive.New` to its accepted group-creation query-result assign, preserving initial forbidden semantics, applying the existing forbidden private-surface treatment on delivered access loss, and retaining generated group identity, typed form/preview/error state, command retry behavior, navigation and UI.",
      "- [x] 009B Migrate `MembaWeb.MySettingsLive` to its accepted settings query-result assign, preserving tab routes, add-email form/validation and verification command feedback while refreshing selected-club, Person, club-membership and email-row data with fresh access checks.",
      "- [x] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks."
    ],
    "pending_obligations": [
      {
        "task_id": "task-009d",
        "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
        "origin": "Delivery-detail page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "status": "prepared",
        "coverage": [
          "One coherent delivery-detail query-result assign for `MembaWeb.MemberMessageDeliveryLive.Show`",
          "Exact-message member delivery-status and staff delivery-reason refreshes",
          "Convergence when the two contributing delivery projectors commit independently in either order",
          "Fresh selected-club, current-member, group-participation and conversation-access checks",
          "Exact unrelated-message isolation and represented Person refreshes",
          "Preserved routes, disclosure state, navigation, existing conversation and delivery behavior and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009e",
        "todo_line": "- [ ] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
        "origin": "Member-invitation page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "status": "pending",
        "coverage": [
          "One coherent invitation-context query-result assign for `MembaWeb.MemberInvitationLive.New`",
          "Selected-club member-count entry and exit refreshes",
          "Fresh selected-club membership and manage-members authorization",
          "Preserved group-aware return routes, invitation form and validation, resend and delivery feedback, commands, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
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
    "candidate_origins": [],
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
          "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
          "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
          "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
          "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
          "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
          "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
          "- [x] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
          "- [x] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
          "- [x] 009A Migrate `MembaWeb.MemberGroupLive.New` to its accepted group-creation query-result assign, preserving initial forbidden semantics, applying the existing forbidden private-surface treatment on delivered access loss, and retaining generated group identity, typed form/preview/error state, command retry behavior, navigation and UI.",
          "- [x] 009B Migrate `MembaWeb.MySettingsLive` to its accepted settings query-result assign, preserving tab routes, add-email form/validation and verification command feedback while refreshing selected-club, Person, club-membership and email-row data with fresh access checks.",
          "- [x] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, all five app-owned query prerequisites, and the completed group-creation, settings and message-compose LiveView migrations."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009d"
        ],
        "scope": "Migrate member delivery detail to its accepted live-query result and converge independently committed exact-message status and reason updates without regressing route, disclosure, access or delivery behavior."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009e"
        ],
        "scope": "Migrate member invitation to its accepted live-query result while preserving return routes, form, resend, feedback and command behavior."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD de561b643279f7a58ade8f3ae8198becae25da83. The trusted baseline and checked todo preserve task 009C as accepted after its bounded worker result and independent accepting review; there are no unaccepted candidate origins. The existing 009A–009E split retains complete lineage from the formerly combined migration obligations, so no todo edit or additional prerequisite is needed. Direct inspection confirms that accepted `MembaWeb.MemberMessageDeliveryQuery`, `LiveQuery.Binding`, and `MembaWeb.LiveQuery.MembaReadModelSource` already provide the coherent `:delivery_detail` result, subscribe-before-read lifecycle, fresh authenticated-email authorization, exact delivery scopes, represented identities, and independent member-status/staff-reason invalidations needed by task 009D. The remaining deficiency is confined to `MembaWeb.MemberMessageDeliveryLive.Show`: it still loads through `MemberMessageDetail` using mount-captured club authority before manually subscribing, spreads projection data across socket assigns, and handles only page-owned access predicates while ignoring both delivery projector families. Task 009D is therefore prepared as one page-sized implementation packet with focused LiveView regression proof. The plan's only allowed acceptance scenario, `Bob sees Alice join without reloading`, is already accepted and green under task 006A and does not exercise delivery detail; 009D is an explicit technical migration with `scenario_focus` null. Broad package bind-window and reconnect proof remains covered by task 011, while the deterministic quality-gate stage and explicit final-validation obligation retain ownership of full `dev check`."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "de561b643279f7a58ade8f3ae8198becae25da83",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-009d-de561b6-delivery-detail-binding-1",
    "task_id": "task-009d",
    "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "de561b643279f7a58ade8f3ae8198becae25da83",
    "outcome": "`MembaWeb.MemberMessageDeliveryLive.Show` owns all projection-backed delivery data through the accepted single `:delivery_detail` live-query result, refreshes exact-message receipt status and staff reason as either committed projector publishes, converges after the later independent commit, rechecks access from fresh authority, and preserves existing routes, disclosure DOM, navigation and UI.",
    "scope": [
      "Bind `MemberMessageDeliveryQuery.query()` during routed mount with the session-selected club ID, routed `message_id`, authenticated identity email, and `MembaReadModelSource.new()`, so connected mount subscribes before reading the coherent delivery detail.",
      "Keep selected club, current member, message metadata, sender, receipt rows, count, summary and groups solely inside the query-owned `:delivery_detail` result. Remove direct `MemberMessageDetail.load/3` ownership, mount-captured `current_identity_clubs` authorization, manual PubSub subscription, access-projector allowlist and page-specific notification predicates.",
      "Adapt rendering and navigation helpers to consume the coherent result while preserving the existing template, copy, stable DOM IDs and data attributes, receipt grouping and ordering, safe zero-recipient presentation, host/path behavior, reply-to-root back link and optional `group_id` return context. Render-time flattening of `:delivery_detail` is acceptable; no second projection-backed result assign may be introduced.",
      "Route `{:read_model_changed, _}` messages through `Binding.handle_notification/2`. Ignore unrelated invalidations and replace the complete delivery result plus interests when exact member-delivery status, exact staff-delivery reason, represented Person, selected Club, current membership/group participation, or exact conversation-access interests match.",
      "Preserve initial `:forbidden` versus `:not_found` behavior. On a relevant refresh access error, rely on the binding-cleared result and preserve navigation to the selected group or `/conversations` so stale private delivery data is not retained; keep unexpected binding, query and source errors visible.",
      "Prove that an already-open delivery page updates receipt rows, groups, counts and percentages after an exact-message `MemberEmailDelivery` invalidation, and updates the rendered failure reason after the matching `MembaStaffEmailDelivery` invalidation.",
      "Prove convergence when member status and staff reason projections commit and notify independently in either order: the first refresh may show only committed state, while the later exact-message notification rereads the joined result and reaches the final status/reason presentation.",
      "Prove exact isolation for another message or delivery, fresh access-loss behavior for current membership/group participation and conversation access, and represented sender or recipient Person refresh where the accepted query result actually changes.",
      "Preserve route parameters, flash, back-link context, navigation and native `<details>` disclosure behavior. Keep stable disclosure element IDs and existing open defaults, and do not introduce LiveView-owned disclosure state that a result refresh resets.",
      "Keep all existing routed rendering, cross-club rejection, unauthenticated return-path, back-link, selected-group context, zero-recipient and conversation-detail regression tests green."
    ],
    "scope_exclusions": [
      "Do not change the accepted `MembaWeb.MemberMessageDeliveryQuery`, `MembaWeb.MemberMessageDetailQuery`, `LiveQuery` package, `MembaWeb.LiveQuery.MembaReadModelSource`, event structs, projectors, projection schemas, routes or domain policy unless a concrete blocker is returned for replanning.",
      "Do not migrate invitation, staff, public, auth, onboarding or stream-backed surfaces; task 009E and out-of-scope surfaces remain separate.",
      "Do not rework the already-accepted conversation-detail or message-compose consumers except for a narrowly necessary focused regression fixture, and do not merge delivery detail into another query registration.",
      "Do not introduce another result query, process-per-query mechanism, manual PubSub subscription, projector allowlist, page-specific event predicate, row patching or broad same-club fallback refresh.",
      "Do not change delivery policy, status grouping, reason disclosure, receipt ordering, message copy, visual design, URLs, group return context or access policy.",
      "Do not add broad package bind-window race or reconnect tests in this packet; task 011 retains residual lifecycle proof after all pages are migrated.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` scenario; it is accepted under task 006A and does not cover delivery detail.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate.",
      "Leave task 009D unchecked and return one bounded candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Approved steps 4–5 require scoped committed-read-model invalidation and migration of every in-scope ordinary-assign member LiveView to one fresh-authorized query result. Delivery detail must converge status and reason from independently committed projectors while preserving route, access, disclosure, navigation and UI behavior."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 009D is the first unchecked obligation. Its accepted delivery-query prerequisite 008E and all migrations through 009C are checked; invitation migration, package integration and residual final proof remain later work."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The delivery-detail row specifies one authorized result with exact message-delivery collection and delivery-identity interests for both member status and staff reason projections, fresh club/member/group/conversation access checks, represented Persons, unrelated-message isolation, and preservation of route parameters and native disclosure behavior."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract gives one query one public result assign, atomically replaces result and interests, subscribes before connected reads, clears failed results, and leaves access transitions plus route, flash, disclosure and navigation state to the LiveView owner."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture requires club-member LiveViews to obtain projection-backed display data through one coherent live-query model and perform fresh authorized rereads on relevant committed changes while keeping Memba notification knowledge outside the generic package."
      },
      {
        "path": "web/lib/memba_web/live/member_message_delivery_live/show.ex",
        "facts": "Current code reads through `MemberMessageDetail.load/3` using mount-captured `current_identity_clubs`, subscribes only after that read, spreads detail fields over ordinary assigns, and refreshes only selected access changes through a projector allowlist. It does not handle either member-status or staff-reason delivery notifications."
      },
      {
        "path": "web/lib/memba_web/member_message_delivery_query.ex",
        "facts": "Accepted query ID `:member_message_delivery` assigns `:delivery_detail`, freshly reuses the authorized conversation-detail boundary from stable club/message/authenticated-email inputs, exposes only delivery-surface data, and registers exact club, membership, Person, group participation, conversation access, message, message-delivery and delivery interests."
      },
      {
        "path": "web/test/memba_web/member_message_delivery_query_test.exs",
        "facts": "Accepted query proof covers result shape and represented interests, normalized attached-email identity, fresh membership authority, forbidden/not-found semantics, reply-to-root delivery scope, both exact delivery projector invalidations, unrelated-message isolation, status/reason convergence in either update order and the zero-recipient model."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted adapter maps both `MemberEmailDelivery` and `MembaStaffEmailDelivery` handled event families to exact `message_deliveries` and `delivery` invalidations, ignores replay-only `EmailDeliveryOpened`, matches by exact equality and surfaces malformed or unsupported known events as contract violations."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "`Binding.bind/4` provides subscribe-before-read and bind-window reconciliation, `Binding.handle_notification/2` refreshes only matching registrations and clears failed results, and successful refreshes replace only the query result and interests without overwriting owner state."
      },
      {
        "path": "web/test/memba_web/live/member_message_delivery_live/show_test.exs",
        "facts": "Existing tests lock initial receipt/status/reason rendering, counts and percentages, cross-club and unauthenticated behavior, root-conversation and selected-group back links, access-loss navigation and zero-recipient output. They do not prove live member-status or staff-reason refresh, independent-projector convergence or unrelated delivery isolation."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/show_test.exs",
        "facts": "The accepted conversation-detail consumer is the nearest application example of binding the shared fresh-authorized detail boundary, handling committed notifications through `Binding`, preserving disclosure owner state and navigating after refresh-time access loss; its existing behavior must not regress."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView navigation must use current APIs, stable DOM IDs should anchor focused selector assertions, and LiveView tests should verify observable outcomes with `has_element?/2`, `element/2` and related helpers rather than raw HTML assertions."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest worker result completed the predecessor 009C migration with one query result, exact invalidations, fresh authority and preserved transient state; focused tests, formatting and diff checks passed, and no unresolved issues or candidate origins were reported."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The latest independent review accepted task 009C, confirmed the generic binding/source consumer pattern and fresh access-error handling, and recorded no review gaps or candidate origins that must carry into task 009D."
      }
    ],
    "constraints": [
      "Use the accepted query inputs, result shape, interest vocabulary and source adapter rather than duplicating reads, authorization or projector/event mapping in the LiveView.",
      "Derive and retain the authenticated identity email as the stable refresh input; do not authorize refreshes from mount-captured club lists, Person rows, memberships or conversation access.",
      "Preserve the query's `:forbidden` versus `:not_found` distinction on initial bind and the existing selected-group-or-conversations private-surface navigation after delivered access loss.",
      "Unexpected binding, query or source errors must remain visible and must not be silently converted into ignored notifications, access loss or broad fallback refreshes.",
      "Successful query replacement may change only the `:delivery_detail` result and binding metadata; route parameters, flash, navigation and browser-owned disclosure state remain outside the query.",
      "Both independently committed delivery projector notifications must trigger an exact-message reread; do not patch receipt status or reason directly from source events.",
      "Keep production changes limited to the delivery-detail LiveView and focused tests unless an in-scope blocker requires replanning."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/member_message_delivery_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs test/memba_web/live/member_message_live/show_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and confirm production changes are limited to `MembaWeb.MemberMessageDeliveryLive.Show` with focused delivery-detail tests unless a blocker was returned.",
      "Report the exact focused validation commands, exit statuses and test counts, including evidence that existing delivery routes, access transitions, receipt presentation, conversation detail, accepted query and source tests remain green.",
      "Identify the sole projection-backed result assign and show that manual subscription, mount-captured authorization, direct detail loading, projector allowlist and page-specific notification filtering were removed.",
      "Summarize focused proof for exact member-status refresh, exact staff-reason refresh, independent-projector convergence in either order, unrelated-message isolation, fresh access loss, represented Person behavior and preservation of route/back-link/disclosure DOM state.",
      "Confirm task 009D remains unchecked, no acceptance feature or delivery artifact was edited, and no `dev check` or other unscoped full-suite command was run."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}