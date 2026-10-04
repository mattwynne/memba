{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c903b57d594f3cad464f907b8b99ae6d7dae7ac6",
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
        "status": "prepared",
        "origin": "Delivery-detail page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "coverage": [
          "One coherent delivery-detail query-result assign for `MembaWeb.MemberMessageDeliveryLive.Show`",
          "Exact-message member delivery-status and staff delivery-reason refreshes",
          "Convergence when the two contributing delivery projectors commit independently in either order",
          "Fresh selected-club, current-member, group-participation and conversation-access checks",
          "Exact unrelated-message isolation and represented Person refreshes",
          "Preserved routes, browser title, native disclosure state, navigation, existing conversation and delivery behavior and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": [
          {
            "base_sha": "de561b643279f7a58ade8f3ae8198becae25da83",
            "head_sha": "ca174b0244fa826f35dff94075e2ec255a6370a7",
            "packet_id": "task-009d-de561b6-delivery-detail-binding-1",
            "reason": "review_revise",
            "task_id": "task-009d",
            "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
          }
        ]
      },
      {
        "task_id": "task-009e",
        "todo_line": "- [ ] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
        "status": "pending",
        "origin": "Member-invitation page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
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
        "base_sha": "de561b643279f7a58ade8f3ae8198becae25da83",
        "head_sha": "ca174b0244fa826f35dff94075e2ec255a6370a7",
        "packet_id": "task-009d-de561b6-delivery-detail-binding-1",
        "reason": "review_revise",
        "task_id": "task-009d",
        "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
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
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, all five app-owned query prerequisites, and completed group-creation, settings and message-compose LiveView migrations."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009d"
        ],
        "scope": "Complete the reviewed delivery-detail migration candidate by restoring socket-level browser-title synchronization and protecting browser-owned native disclosure state across live-query patches, while retaining its exact status/reason convergence, fresh authorization and isolation behavior."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD c903b57d594f3cad464f907b8b99ae6d7dae7ac6. All checked todo lines remain preserved exactly and the existing 009D–009E, 010 and 011 split still accounts for every approved obligation, so todo.md required no edit. Task 009D remains the first unchecked line and retains the unaccepted candidate from packet task-009d-de561b6-delivery-detail-binding-1. Its worker result reports the one-result delivery migration and 88 focused tests passing, but the latest independent review requires revision: render-local flattening leaves `page_title` nested under `delivery_detail`, so the root layout does not receive its socket-level title assign, and the new live patches can overwrite browser-owned `<details open>` toggles because the disclosure elements lack `JS.ignore_attributes([\"open\"])` or equivalent protection. The revision keeps the same task identity and candidate lineage, synchronizes the shell title after initial bind and successful refresh, protects native disclosure state while retaining initial defaults and stable IDs, and adds focused title/disclosure proof. The plan's sole acceptance scenario is already green and accepted under task 006A and does not exercise these technical delivery-page shell gaps, so scenario_focus is explicitly null. Full `dev check` remains owned by the deterministic quality-gate stage and final task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c903b57d594f3cad464f907b8b99ae6d7dae7ac6",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-009d-c903b57-title-disclosure-revision-2",
    "task_id": "task-009d",
    "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
    "attempt": "revision",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "c903b57d594f3cad464f907b8b99ae6d7dae7ac6",
    "outcome": "The existing task 009D candidate retains its accepted single-result live-query behavior while restoring the delivery page's browser title and ensuring LiveView result patches do not reset user-controlled native receipt-group disclosure state.",
    "scope": [
      "Preserve the candidate's accepted `:member_message_delivery` binding, single `:delivery_detail` projection-backed result assign, exact invalidations, fresh authorization, access transitions, routes, navigation and rendering behavior.",
      "After a successful initial `Binding.bind/4`, copy `delivery_detail.page_title` into the socket-level `:page_title` assign consumed by the root layout, following the accepted conversation-detail consumer's shell-synchronization pattern.",
      "After every successful relevant `Binding.handle_notification/2` refresh, resynchronize socket-level `:page_title` from the replacement `delivery_detail`; ignored notifications must remain no-ops.",
      "On refresh-time forbidden or not-found access loss, clear any socket-level private page title before navigating away, consistently with the accepted conversation-detail private-surface transition.",
      "Mark each stable receipt-group `<details>` element so LiveView ignores future server changes to its browser-owned `open` attribute, using `phx-mounted={JS.ignore_attributes([\"open\"])}` or an equivalent supported LiveView mechanism.",
      "Retain the existing initial server defaults: delivery-problem groups initially render open and other groups initially render closed. Keep existing stable detail and summary IDs, accessibility relationships, ordering and copy.",
      "Add focused proof that the connected delivery page exposes the expected root-layout title after initial binding and still synchronizes the title after a successful relevant query replacement.",
      "Add focused proof that receipt-group disclosures emit the supported open-attribute preservation instruction while retaining their initial open/closed defaults and stable IDs.",
      "Keep all existing task 009D proof green, including exact member-status refresh, exact staff-reason refresh, independent-projector convergence in both orders, unrelated-message isolation, represented Person refresh, fresh access loss, routes, flash, back links, receipt presentation and zero-recipient behavior."
    ],
    "scope_exclusions": [
      "Do not replace, discard or mark accepted the existing unaccepted task 009D candidate; revise it in place under the same task identity and preserve its candidate provenance.",
      "Do not change the accepted `MembaWeb.MemberMessageDeliveryQuery`, `MembaWeb.MemberMessageDetailQuery`, generic LiveQuery package, Memba source adapter, projectors, event structs, schemas, routes or domain policy.",
      "Do not introduce LiveView-owned receipt-group toggle state, click handlers, custom hooks or raw JavaScript; native `<details>` remains browser-owned.",
      "Do not add another query result assign, manual PubSub subscription, page-specific projector predicate, event-driven field patch or broad fallback invalidation.",
      "Do not alter delivery status grouping, reason disclosure, receipt ordering, message copy, visual design, URLs, selected-group return context or authorization policy.",
      "Do not migrate invitation or any staff, public, auth, onboarding or stream-backed surface.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` scenario; it is accepted under task 006A and does not cover this technical revision.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and final-validation obligation own the iteration-wide gate.",
      "Leave task 009D unchecked and return the revised candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Approved implementation step 5 requires each in-scope member LiveView to use one query-result assign while preserving routes, access transitions, transient UI and existing presentation; delivery detail must converge independently committed member-status and staff-reason updates."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 009D is the first unchecked obligation. Its delivery-query prerequisite is accepted, while invitation migration, package integration and final proof remain separate later tasks."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review returned `revise`: socket-level `page_title` was lost because render-local result flattening cannot populate the root layout assign, and browser-owned `<details open>` state was not protected from live patches. It explicitly requests title synchronization after initial bind and successful refresh, `JS.ignore_attributes([\"open\"])` or equivalent disclosure protection, and focused proof."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The existing candidate changed only the delivery LiveView and focused tests, passed its 88-test focused command plus formatting and whitespace checks, and reported no unresolved implementation blockers. That candidate remains unaccepted and must be preserved while repairing the review gaps."
      },
      {
        "path": "web/lib/memba_web/live/member_message_delivery_live/show.ex",
        "facts": "Current candidate code successfully binds and refreshes `:delivery_detail`, but returns the bound socket directly on mount and refresh. Its `page_title` stays nested in the result, and receipt-group `<details>` elements render an `open` default without a `phx-mounted` open-attribute preservation command."
      },
      {
        "path": "web/test/memba_web/live/member_message_delivery_live/show_test.exs",
        "facts": "Current focused proof covers routed rendering, initial disclosure defaults, exact delivery refreshes, convergence, isolation, represented Person updates and access loss. Its disclosure assertion only rechecks the server default and does not verify an open-attribute preservation instruction; it also lacks root-layout page-title assertions."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/show.ex",
        "facts": "The accepted conversation-detail consumer calls a shell synchronization helper after initial bind and successful notification refresh, copies nested result `page_title` into the socket-level assign, and clears it during refresh-time access loss. This is the nearest accepted pattern."
      },
      {
        "path": "web/lib/memba_web/components/layouts/root.html.heex",
        "facts": "The root layout's `<.live_title>` reads `assigns[:page_title]`, so a title nested only inside `delivery_detail` cannot update the browser title."
      },
      {
        "path": "web/lib/memba_web/member_message_delivery_query.ex",
        "facts": "The accepted coherent result includes `page_title` together with the selected club, member, message, sender and receipt presentation. The LiveView may mirror only the shell title while keeping projection-backed display data in the sole `:delivery_detail` result."
      },
      {
        "path": "web/deps/phoenix_live_view/lib/phoenix_live_view/js.ex",
        "facts": "`Phoenix.LiveView.JS.ignore_attributes/1` is the supported mechanism for preventing future LiveView patches from changing browser-owned attributes; its documentation uses `phx-mounted` and the `open` attribute as the relevant pattern."
      },
      {
        "path": "web/deps/phoenix_live_view/CHANGELOG.md",
        "facts": "Phoenix LiveView specifically documents native `<details>` as a use case for `phx-mounted={JS.ignore_attributes([\"open\"])}`, preserving later browser changes to the open attribute during server patches."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "Focused LiveView tests should assert observable behavior through stable DOM IDs and supported LiveView helpers. The revision must retain the existing stable disclosure IDs and current navigation APIs."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture requires one coherent query model with fresh authorized rereads while replacement of that query assign leaves navigation and transient UI state alone; browser-owned disclosure state is therefore outside the query result."
      }
    ],
    "constraints": [
      "Keep the same `task-009d` obligation and carry the required review-revise candidate origin unchanged.",
      "Treat the current candidate's exact invalidation, fresh authorization and one-result migration as unaccepted candidate work to preserve, not as accepted evidence.",
      "Use a small shell-synchronization helper or equivalent bounded code so initial bind and successful refresh cannot diverge.",
      "Socket-level `:page_title` is shell metadata mirrored from the coherent result, not a second projection-backed result boundary.",
      "Browser-owned `open` state must survive future relevant LiveView patches; retaining only the server's initial `open` expression is insufficient.",
      "`JS.ignore_attributes` only protects future changes after connected mount, so the server must continue rendering the correct initial open/closed defaults.",
      "Unexpected binding, query or source errors must remain visible and must not be converted to ignored notifications or access loss.",
      "Production changes should remain limited to `MembaWeb.MemberMessageDeliveryLive.Show`, with focused changes in its test file, unless a concrete blocker is returned for replanning."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/member_message_delivery_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs test/memba_web/live/member_message_live/show_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and confirm production changes remain limited to the delivery-detail LiveView unless a blocker required replanning.",
      "Report exact focused validation commands, exit statuses and test counts.",
      "Show focused evidence that the root-layout browser title is correct after initial binding and remains synchronized after a successful relevant result refresh.",
      "Show focused evidence that each stable receipt-group `<details>` emits the supported `open`-attribute preservation instruction while delivery-problem and non-problem groups retain their established initial defaults.",
      "Confirm access-loss handling clears stale title state before navigation and existing exact status/reason refresh, convergence, isolation, routes, flash, back-link, disclosure IDs and zero-recipient tests remain green.",
      "Confirm the single projection-backed result remains `:delivery_detail`; no LiveView-owned disclosure state, manual subscription, page predicate or second result assign was introduced.",
      "Confirm task 009D remains unchecked, the candidate origin is preserved, no acceptance feature or delivery artifact was edited, and no unscoped full-suite command was run."
    ],
    "candidate_origins": [
      {
        "base_sha": "de561b643279f7a58ade8f3ae8198becae25da83",
        "head_sha": "ca174b0244fa826f35dff94075e2ec255a6370a7",
        "packet_id": "task-009d-de561b6-delivery-detail-binding-1",
        "reason": "review_revise",
        "task_id": "task-009d",
        "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
      }
    ],
    "scenario_focus": null
  }
}