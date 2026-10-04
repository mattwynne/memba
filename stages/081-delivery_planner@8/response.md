{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "4621875c861b0e8db7fa4b7f1b3e919c0a68686a",
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
      "- [x] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state."
    ],
    "pending_obligations": [
      {
        "task_id": "task-009a",
        "todo_line": "- [ ] 009A Migrate `MembaWeb.MemberGroupLive.New` to its accepted group-creation query-result assign, preserving initial forbidden semantics, applying the existing forbidden private-surface treatment on delivered access loss, and retaining generated group identity, typed form/preview/error state, command retry behavior, navigation and UI.",
        "status": "prepared",
        "origin": "Group-creation page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "coverage": [
          "One coherent `group_creation_context` query-result assign for `MembaWeb.MemberGroupLive.New`",
          "Subscribe-before-read binding through the accepted generic package and Memba committed-read-model source",
          "Fresh selected-club membership and manage-members authorization on relevant notifications",
          "Initial forbidden behavior and forbidden private-surface treatment after delivered access loss",
          "Preserved route parameters, generated group ID, typed form, preview, validation errors, command retry state, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009b",
        "todo_line": "- [ ] 009B Migrate `MembaWeb.MySettingsLive` to its accepted settings query-result assign, preserving tab routes, add-email form/validation and verification command feedback while refreshing selected-club, Person, club-membership and email-row data with fresh access checks.",
        "status": "pending",
        "origin": "Settings-page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "coverage": [
          "One coherent settings query-result assign for `MembaWeb.MySettingsLive`",
          "Fresh selected-club, current Person, active-club-membership and email-row refreshes",
          "Fresh selected-club access checks and exact unrelated-Person isolation",
          "Preserved tab routes, add-email form and validation, verification feedback, commands, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009c",
        "todo_line": "- [ ] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks.",
        "status": "pending",
        "origin": "Message-compose page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "coverage": [
          "One coherent compose-context query-result assign for `MembaWeb.MemberMessageLive.New`",
          "Fresh selected-club, audience participation, represented-Person eligibility and recipient-count refreshes",
          "Fresh authorization and existing conversation-compose route and audience behavior",
          "Preserved typed subject/body, validation, send and retry state, commands, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009d",
        "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
        "status": "pending",
        "origin": "Delivery-detail page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "coverage": [
          "One coherent delivery-detail query-result assign for `MembaWeb.MemberMessageDeliveryLive.Show`",
          "Exact-message member delivery-status and staff delivery-reason refreshes",
          "Convergence when the two contributing delivery projectors commit independently in either order",
          "Fresh conversation access checks and unrelated-message isolation",
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
    "candidate_origins": [],
    "coverage_map": [
      {
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, and all five remaining app-owned query prerequisites through invitation.",
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
          "- [x] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state."
        ],
        "pending_task_ids": []
      },
      {
        "scope": "Migrate the member group-creation surface to its accepted live-query result while preserving access and transient form/command behavior.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009a"
        ]
      },
      {
        "scope": "Migrate member settings to its accepted live-query result while preserving tab, form, verification and navigation behavior.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009b"
        ]
      },
      {
        "scope": "Migrate member message composition to its accepted live-query result while preserving audience, form, send and retry behavior.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009c"
        ]
      },
      {
        "scope": "Migrate member delivery detail to its accepted live-query result and converge independently committed status and reason updates without regressing conversation or delivery behavior.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009d"
        ]
      },
      {
        "scope": "Migrate member invitation to its accepted live-query result while preserving return routes, form, resend, feedback and command behavior.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009e"
        ]
      },
      {
        "scope": "Complete production package, Docker release and repository quality-gate integration.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-010"
        ]
      },
      {
        "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation.",
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011"
        ]
      }
    ],
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 4621875c861b0e8db7fa4b7f1b3e919c0a68686a. The trusted baseline and checked todo preserve task 008F as accepted after its bounded worker result and independent accepting review, and no unaccepted candidate origin remains. The former task 009 combined five independent LiveView migrations, so it was split into ordered page-sized obligations 009A through 009E; every slice records lineage to both the replaced task 009 line and its earlier task 006 origin, and together they preserve the one-result-assign, access, transient-state, command, navigation, delivery/conversation and no-staff-stream obligations. Direct inspection confirms that all five app-owned queries, the generic package and the audited Memba source already exist, and task 010 package/build integration is not a prerequisite for using the dependency in web-focused migrations. Task 009A is first because group creation has no dependency on another 009 migration and is bounded to one LiveView plus its focused tests. The only approved acceptance scenario is already accepted and green under task 006A and does not cover this group-creation technical migration, so scenario_focus is null. Broader bind-race, reconnect and final full-gate proof remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "4621875c861b0e8db7fa4b7f1b3e919c0a68686a",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-009a-4621875-group-live-binding-1",
    "task_id": "task-009a",
    "todo_line": "- [ ] 009A Migrate `MembaWeb.MemberGroupLive.New` to its accepted group-creation query-result assign, preserving initial forbidden semantics, applying the existing forbidden private-surface treatment on delivered access loss, and retaining generated group identity, typed form/preview/error state, command retry behavior, navigation and UI.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "4621875c861b0e8db7fa4b7f1b3e919c0a68686a",
    "outcome": "Make the member group-creation page obtain its selected Club and current member exclusively through the accepted live-query binding, so relevant committed changes trigger a fresh authorized reread and delivered access loss leaves the private surface, while the generated group identity, typed form, preview, validation, retry, command, route and navigation state remain LiveView-owned and unchanged by successful refreshes.",
    "scope": [
      "Change only `web/lib/memba_web/live/member_group_live/new.ex` and focused coverage in `web/test/memba_web/live/member_group_live/new_test.exs` unless a directly encountered compile issue requires a narrowly justified adjacent test-support adjustment.",
      "Alias and use `LiveQuery.Binding`, `MembaWeb.LiveQuery.MembaReadModelSource`, and the accepted `MembaWeb.MemberGroupCreationQuery`; use query ID `:member_group_creation` and its existing `:group_creation_context` result assign.",
      "During mount, retain the routed `club_id`, authenticated email and all transient initial state, then call `Binding.bind/4` with `%{club_id: club_id, authenticated_email: socket.assigns.current_identity_email}` and `MembaReadModelSource.new/0`; the connected lifecycle must subscribe before reading through the package contract.",
      "Render and execute preview/create commands from the coherent `group_creation_context` result. Flatten it only into temporary render assigns if useful; do not restore separate projection-backed `selected_club` or `current_member` socket ownership.",
      "Remove the superseded LiveView-owned `group_context/3` and email-based `current_member/2` read path, along with aliases made unused by that removal.",
      "Route `{:read_model_changed, _}` messages through `Binding.handle_notification/2`; ignore unrelated notifications, keep transient assigns untouched after successful relevant refreshes, and apply the page's existing `forbidden!` private-surface treatment when the initial bind or a relevant refresh returns `{:member_group_creation, :forbidden}`.",
      "Preserve existing group name preview and create-command behavior, generated `group_id`, `route_params`, typed form contents, form validity, preview text/note, validation errors, retry behavior, flash messages, host-aware links, successful navigation and rendered UI.",
      "Add focused LiveView proof that a matching committed-source classification refreshes the coherent context, a successful refresh preserves generated identity and in-progress form/preview/error state, fresh membership or manage-members loss causes the forbidden transition, and an unrelated notification neither replaces the context nor disturbs transient state.",
      "Keep all existing route, signed-out, ordinary-member, preview, stale-preview, successful-create, technical-failure, authorization-mismatch and submit-time-permission-loss tests green."
    ],
    "scope_exclusions": [
      "Do not change the accepted `MembaWeb.MemberGroupCreationQuery`, `LiveQuery` package, `MembaWeb.LiveQuery.MembaReadModelSource`, authorization/read APIs, projectors, event structs, projections, schemas, commands or routes.",
      "Do not migrate settings, message compose, delivery detail, invitation, staff, public, auth, onboarding or stream-backed surfaces; those remain later or out-of-scope obligations.",
      "Do not change group-creation domain policy, command authorization, preview allocation, form copy, visual design, URL behavior or the distinction between technical retry and authorization failure.",
      "Do not add a second result query, process-per-query mechanism, manual PubSub subscription, projector allowlist or page-specific event predicate.",
      "Do not add broad bind-window race, reconnect or package lifecycle tests in this packet; task 011 retains residual lifecycle proof after all pages are migrated.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate.",
      "Leave task 009A unchecked and return one bounded candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved contract requires one coherent query result per assign, LiveView-owned subscription, subscribe-before-connected-read behavior, fresh authorization on refresh, replacement rather than event-field patching, and preservation of form, route, command and navigation state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 009A is the first unchecked obligation and limits this visit to migrating `MembaWeb.MemberGroupLive.New`; settings, compose, delivery, invitation, package integration and final proof remain later lines."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint preserves every checked line through 008F, has no required candidate origin, and binds this planner visit to the accepted post-008F state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted the preceding 008F candidate and retained no candidate provenance, so task 009A is a fresh implementation rather than a revision."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/wip-after.json",
        "facts": "The only approved acceptance scenario, `Bob sees Alice join without reloading`, is already green and belongs to accepted task 006A; it must not be reset for this unrelated group-creation migration."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The group-creation row requires one fresh-authorized selected-club/current-member result; relevant Club, Membership, Person and role/permission changes recheck access, while route parameters, generated group ID, name form, preview, retry, command, flash and navigation state remain LiveView-owned."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract gives each query a stable identity and one public result assign, subscribes before the connected read, refreshes only matching registrations, clears failed results and leaves access-error navigation or raising to the LiveView owner."
      },
      {
        "path": "web/lib/memba_web/live/member_group_live/new.ex",
        "facts": "The current page directly builds `selected_club` and `current_member` from mount-captured clubs and an email comparison, has no committed-change handler, and stores generated ID, route, form, preview, retry, flash and navigation behavior that the migration must preserve."
      },
      {
        "path": "web/test/memba_web/live/member_group_live/new_test.exs",
        "facts": "Existing tests lock the exact route, initial manage-members authorization, signed-out behavior, name-only form, preview allocation, typed-input preservation, stale-preview command recheck, successful navigation, technical retry, authorization mismatch and submit-time permission-loss behavior."
      },
      {
        "path": "web/lib/memba_web/member_group_creation_query.ex",
        "facts": "The accepted descriptor uses ID `:member_group_creation`, assign `:group_creation_context`, stable club/email inputs and fresh active-club, Person, membership and manage-members reads; it returns selected Club and current member with exact Club, Membership, Person and role/permission interests."
      },
      {
        "path": "web/test/memba_web/member_group_creation_query_test.exs",
        "facts": "Accepted query proof covers the exact result and interests, attached-email identity resolution by Person ID, fresh selected-membership loss, fresh manage-members permission loss, fail-closed invalid contexts and exclusion of form, preview, retry and command state."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "`bind/4` subscribes a connected owner before loading, `handle_notification/2` classifies and refreshes only matching registrations, successful reads atomically replace result and interests, and failed refreshes clear the result before returning query errors."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted Memba source subscribes to committed read-model notifications and maps valid Club, Membership, Person and Role projector events to the exact interests already returned by the group-creation query."
      },
      {
        "path": "web/lib/memba_web/live/member_dashboard_live.ex",
        "facts": "The accepted dashboard consumer demonstrates app integration with `Binding.bind/4`, `Binding.handle_notification/2`, `MembaReadModelSource.new/0`, stable authenticated-email inputs and explicit query-error handling without manual projector predicates."
      },
      {
        "path": "web/lib/memba_web/identity_auth.ex",
        "facts": "The club-member LiveView on-mount path supplies normalized `current_identity_email`; the group page can use this stable identity input instead of mount-captured active-club rows."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture places authorized Memba query composition in the app, generic binding in the local package, and one coherent result assign in each club-member LiveView while leaving staff streams deferred."
      },
      {
        "path": "docs/adr/0021-publish-committed-read-model-changes.md",
        "facts": "Notifications are emitted after projector transactions commit, so a matching notification must trigger a fresh projection read rather than patching the view model from event fields."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "Focused LiveView tests should assert stable element IDs and observable outcomes, while form state remains represented by an assigned `to_form` value."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use focused file-level ExUnit coverage and deterministic process synchronization, avoiding sleeps and broad unrelated test commands."
      }
    ],
    "constraints": [
      "Use the existing accepted query, source and binding APIs without widening their public contracts.",
      "Maintain exactly one projection-backed public result assign for this page.",
      "Use `current_identity_email` as the stable identity input and never use mount-captured `current_identity_clubs` as refresh authority.",
      "Treat valid notifications as invalidation hints and reread projections; do not patch result fields from source events.",
      "Preserve the current initial `MembaWeb.ForbiddenError` behavior and use the same forbidden private-surface treatment for delivered fresh-authorization loss.",
      "A successful query refresh may replace only `group_creation_context`; generated identity, route, form, preview, validation, retry, flash and navigation state must survive.",
      "An unrelated notification must not invoke or replace the group-creation query result.",
      "Keep source and tests formatted and free of compiler warnings.",
      "Do not mark task 009A accepted or edit its checkbox."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live/member_group_live/new_test.exs test/memba_web/member_group_creation_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and confirm that changes are limited to the group-creation LiveView and its focused test unless a narrowly justified adjacent test-support change was necessary.",
      "Report the focused test command, exit status and test/failure count.",
      "Report formatting and `git diff --check` results.",
      "Identify the final coherent result assign and confirm the old direct `group_context/3` and email-comparison member lookup are removed.",
      "Summarize focused evidence for relevant refresh, fresh delivered access loss, unrelated-notification isolation and preservation of generated ID plus in-progress form/preview/error state.",
      "Confirm existing preview, create, retry, navigation and submit-time authorization tests remain green.",
      "Confirm no approved feature, plan, todo, ADR, migration matrix, package, adapter, query, projector, event, schema, command, route or later LiveView migration was changed.",
      "Leave task 009A unchecked and return the candidate for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}