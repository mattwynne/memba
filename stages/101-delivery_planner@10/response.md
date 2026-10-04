{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5b39ca03d5672ef4f596f724a5c1ebe029901e81",
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
      "- [x] 009B Migrate `MembaWeb.MySettingsLive` to its accepted settings query-result assign, preserving tab routes, add-email form/validation and verification command feedback while refreshing selected-club, Person, club-membership and email-row data with fresh access checks."
    ],
    "pending_obligations": [
      {
        "candidate_origins": [],
        "coverage": [
          "One coherent compose-context query-result assign for `MembaWeb.MemberMessageLive.New`",
          "Fresh selected-club, audience participation, represented-Person eligibility and recipient-count refreshes",
          "Fresh authorization and existing conversation-compose route and audience behavior",
          "Preserved typed subject/body, validation, send and retry state, commands, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "origin": "Message-compose page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "status": "prepared",
        "task_id": "task-009c",
        "todo_line": "- [ ] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "One coherent delivery-detail query-result assign for `MembaWeb.MemberMessageDeliveryLive.Show`",
          "Exact-message member delivery-status and staff delivery-reason refreshes",
          "Convergence when the two contributing delivery projectors commit independently in either order",
          "Fresh conversation access checks and unrelated-message isolation",
          "Preserved routes, disclosure state, navigation, existing conversation and delivery behavior and UI",
          "No staff or stream-backed surface changes"
        ],
        "origin": "Delivery-detail page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "status": "pending",
        "task_id": "task-009d",
        "todo_line": "- [ ] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "One coherent invitation-context query-result assign for `MembaWeb.MemberInvitationLive.New`",
          "Selected-club member-count entry and exit refreshes",
          "Fresh selected-club membership and manage-members authorization",
          "Preserved group-aware return routes, invitation form and validation, resend and delivery feedback, commands, flash, navigation and UI",
          "No staff or stream-backed surface changes"
        ],
        "origin": "Member-invitation page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "replaces": [
          "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "status": "pending",
        "task_id": "task-009e",
        "todo_line": "- [ ] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access."
      },
      {
        "candidate_origins": [],
        "coverage": [
          "Path dependency integration in web/mix.exs",
          "Production Docker build and release inclusion",
          "Package tests exercised by dev check in supported environments"
        ],
        "origin": "Approved implementation step 6.",
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
          "Focused proof for every migrated member page",
          "Residual package lifecycle and bind/reconnect race coverage",
          "Final full dev check on the exact clean or staged state"
        ],
        "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
        "replaces": [
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
          "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
        ],
        "status": "pending",
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
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
          "- [x] 009B Migrate `MembaWeb.MySettingsLive` to its accepted settings query-result assign, preserving tab routes, add-email form/validation and verification command feedback while refreshing selected-club, Person, club-membership and email-row data with fresh access checks."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, all five app-owned query prerequisites, and the completed group-creation and settings LiveView migrations."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009c"
        ],
        "scope": "Migrate member message composition to its accepted live-query result while preserving audience, form, send and retry behavior."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009d"
        ],
        "scope": "Migrate member delivery detail to its accepted live-query result and converge independently committed status and reason updates without regressing conversation or delivery behavior."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 5b39ca03d5672ef4f596f724a5c1ebe029901e81. The trusted baseline and checked todo preserve task 009B as accepted after its bounded worker result and independent accepting review; there are no unaccepted candidate origins. The existing 009A–009E split still records complete lineage from the formerly combined migration obligations, so no todo edit or additional prerequisite is needed. Direct inspection confirms that accepted `MembaWeb.MemberMessageComposeQuery`, `LiveQuery.Binding`, and `MembaWeb.LiveQuery.MembaReadModelSource` provide the coherent query, lifecycle, and exact Club, Membership, Person, Group and GroupMembership invalidation prerequisites for 009C. The remaining deficiency is confined to `MembaWeb.MemberMessageLive.New`, which still reads five projection-backed values from mount-captured authority before manually subscribing and broadly reloads only three projector families. Task 009C is therefore prepared as one page-sized implementation packet. The plan's only allowed acceptance scenario, `Bob sees Alice join without reloading`, is already accepted and green under task 006A and exercises the member-list surface rather than message composition; 009C is an explicit technical migration with focused LiveView/query/source proof and `scenario_focus` null. Broad package bind-window and reconnect proof remains covered by task 011, and the iteration-wide `dev check` remains owned by the deterministic gate and explicit final-validation obligation."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5b39ca03d5672ef4f596f724a5c1ebe029901e81",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-009c-5b39ca0-message-compose-binding-1",
    "task_id": "task-009c",
    "todo_line": "- [ ] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "5b39ca03d5672ef4f596f724a5c1ebe029901e81",
    "outcome": "`MembaWeb.MemberMessageLive.New` owns all projection-backed compose data through the accepted single `:compose_context` live-query result, refreshes audience display and recipient eligibility on exact committed invalidations with fresh authorization, and preserves existing route, typed form, validation, send/retry, navigation and UI behavior.",
    "scope": [
      "Bind `MemberMessageComposeQuery.query()` during routed mount with the session-selected club ID, optional routed `group_id`, `socket.assigns.current_identity_email`, and `MembaReadModelSource.new()`, so a connected mount subscribes before reading the coherent compose context.",
      "Keep `selected_club`, `current_member`, `audience_group`, `active_member_count`, and `message_audience` solely inside the query-owned `:compose_context` result; remove their independent projection ownership, the direct `compose_context/4` read path, mount-captured `current_identity_clubs` authorization, manual PubSub subscription, projector allowlist and page-specific event predicate.",
      "Adapt rendering, send helpers, navigation helpers and logging to consume the coherent result while preserving the existing template, DOM contract, Everyone default audience and explicit-group route semantics. Render-time flattening of `:compose_context` is acceptable, but no second projection-backed result assign may be introduced.",
      "Route `{:read_model_changed, _}` messages through `Binding.handle_notification/2`; ignore unrelated notifications and replace the complete compose result plus interests after matching exact Club, Membership, Person, Group or GroupMembership invalidations.",
      "Preserve initial error semantics: a missing or lost club/default-audience context remains forbidden, while an unavailable explicit audience remains not found. On a relevant refresh access error, rely on the binding-cleared result and preserve the existing clear/private-surface navigation to the selected group or `/conversations`; keep unexpected binding/source failures visible.",
      "Before sending, freshly reread the coherent query with `Binding.rebind/3` and the same stable route and authenticated-email inputs instead of calling the superseded page-local loader. Continue to rely on the existing domain command for authoritative send behavior and preserve eventual-projection failure handling.",
      "Preserve `route_params`, `message_form` subject/body, `compose_state`, `sent_message_id`, `send_error`, `body_error`, flash and navigation as LiveView-owned state across every successful notification refresh or send-time rebind.",
      "Add focused LiveView proof that selected-group participant entry/exit and represented-Person primary-email eligibility changes update recipient count and audience data; exact Club or Group changes refresh represented copy; unrelated clubs, groups and Persons do not replace the result; and club-membership or selected-group participation loss applies fresh access semantics.",
      "Add focused proof that a successful relevant refresh preserves typed subject/body and validation/error or retry state, while all existing default/explicit audience routes, form affordances, send, validation, retry, provider-failure, projection-lag and navigation tests remain green."
    ],
    "scope_exclusions": [
      "Do not change the accepted `MembaWeb.MemberMessageComposeQuery`, the `LiveQuery` package, `MembaWeb.LiveQuery.MembaReadModelSource`, Membership participant API, event structs, projectors, projection schemas, routes or domain policy unless a concrete blocker is returned for replanning.",
      "Do not migrate delivery detail, invitation, staff, public, auth, onboarding or stream-backed surfaces; tasks 009D–009E and out-of-scope surfaces remain separate.",
      "Do not introduce another result query, process-per-query mechanism, manual PubSub subscription, projector allowlist, page-specific event predicate or broad same-club fallback refresh.",
      "Do not change audience policy, recipient eligibility rules, Everyone defaults, message copy, visual design, URL/group context, send consistency, provider behavior or navigation.",
      "Do not reset typed form, validation, send-failure or retry state during successful query refreshes or rebinds.",
      "Do not add broad package bind-window race or reconnect tests in this packet; task 011 retains residual lifecycle proof after all pages are migrated.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` scenario; it is accepted under task 006A and does not cover message composition.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate.",
      "Leave task 009C unchecked and return one bounded candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Approved steps 4–5 require Memba-scoped committed invalidations and migration of every in-scope ordinary-assign member LiveView to one fresh-authorized query result while preserving route, form, command, navigation and UI state. Message compose must update audience membership and represented-Person recipient eligibility without page-owned event filtering."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 009C is the first unchecked obligation. Tasks through 009B and the compose-query prerequisites 008D1–008D2 are checked; delivery detail, invitation, package integration and residual final proof remain later work."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The compose row specifies one result containing selected club/member, authorized audience group, recipient count and audience display data; interests for selected Club, current membership/Person, current-person groups, selected Group, group members and represented Persons; fresh authenticated-email authority; and preservation of subject/body, send/retry state and route context."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract gives one query one public result assign, atomically replaces result and interests, subscribes before connected reads, clears failed results, and leaves access transitions plus route/form/flash/command state to the LiveView owner."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture requires club-member LiveViews to obtain projection-backed display data through one coherent live-query model and perform fresh authorized rereads on relevant committed changes while keeping Memba notification knowledge outside the generic package."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/new.ex",
        "facts": "Current code computes five projection-backed assigns from `current_identity` and mount-captured `current_identity_clubs`, subscribes only after the read, broadly reloads for same-club Group, GroupMembership and Membership projectors, omits Person and Club invalidations, and directly reloads before send. Form, validation, send/retry and navigation state are separately socket-owned."
      },
      {
        "path": "web/lib/memba_web/member_message_compose_query.ex",
        "facts": "Accepted query ID `:member_message_compose` assigns `:compose_context`, freshly resolves active-club authority and Person/member identity from normalized authenticated email, distinguishes forbidden default context from not-found explicit audience, includes participants without primary email, derives recipient eligibility, and registers complete exact and collection interests."
      },
      {
        "path": "web/test/memba_web/member_message_compose_query_test.exs",
        "facts": "Accepted query proof covers default Everyone and explicit audiences, complete interests, attached-email identity, forbidden/not-found distinctions, fresh club and group access loss, primary-email eligibility changes, selected-group entry/exit with interest replacement, unrelated isolation and fail-closed contexts."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted adapter maps Club, Membership, Person, Group and GroupMembership event families to exact tuple invalidations used by the compose query, matches by exact equality, ignores unrelated projector work and surfaces malformed or unsupported known projector payloads as contract violations."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "`Binding.bind/4` provides subscribe-before-read and bind-window reconciliation, `Binding.handle_notification/2` refreshes only matching registrations and clears failed results, and `Binding.rebind/3` rereads stable inputs while replacing result and interests without overwriting unrelated socket assigns."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/new_test.exs",
        "facts": "Existing LiveView tests lock isolated and routed shells, host-selected club behavior, Everyone and explicit-group audience copy/count/email, initial forbidden/not-found semantics, one delivered group-access-loss transition, recipient eligibility rendering, form affordances, inbound address and sign-in routing. They do not yet prove live group entry/exit, Person eligibility refresh, exact unrelated isolation or transient form preservation."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/new_send_test.exs",
        "facts": "Existing command tests lock Everyone and explicit-audience sends, fresh submit-time participation checks, validation, send failure and retry, projection-lag fail-closed behavior, delivery-projector independence and provider-failure success semantics; these must remain green after the query binding replaces direct reloads."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "LiveView forms remain socket-owned `to_form/2` assigns with stable DOM IDs, navigation uses current LiveView APIs, and focused tests should assert observable behavior through LiveView selectors and events."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "The latest independent review accepted task 009B, confirmed the generic binding/source page-consumer pattern, and recorded no candidate origins or revision gaps that must carry into task 009C."
      }
    ],
    "constraints": [
      "Use the accepted query inputs, result shape, interest vocabulary and source adapter rather than duplicating their reads or event-mapping logic in the LiveView.",
      "Use `socket.assigns.current_identity_email` as the fresh identity input; do not authorize refreshes from mount-captured club lists, Person data or membership data.",
      "Preserve the query's `:forbidden` versus `:not_found` distinction on initial bind and the existing clear-then-navigate private-surface behavior after delivered access loss.",
      "Unexpected binding or source errors must remain visible and must not be silently converted into ignored notifications, access loss or broad fallback refreshes.",
      "Successful query replacement may change only the `:compose_context` result and binding metadata; route, message form, validation, send/retry, flash and navigation state remain owned by the LiveView.",
      "Send-time consistency must use a fresh coherent query reread without changing the established domain-command authorization or delivery behavior.",
      "Keep production changes limited to the message-compose LiveView and focused tests unless an in-scope blocker requires replanning."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs test/memba_web/member_message_compose_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and confirm production changes are limited to `MembaWeb.MemberMessageLive.New` with focused compose tests unless a blocker was returned.",
      "Report the exact focused validation commands, exit statuses and test counts, including evidence that existing compose routes, sends, validation/retry behavior and accepted query/source tests remain green.",
      "Identify the sole projection-backed result assign and show that manual subscription, mount-captured authorization, direct compose loaders, projector allowlist and page-specific notification filtering were removed.",
      "Summarize proof for group participant entry/exit, represented-Person recipient-eligibility refresh, represented Club/Group refresh, exact unrelated isolation, fresh access loss and preservation of typed form plus validation/send-retry state.",
      "Confirm task 009C remains unchecked, no acceptance feature or delivery artifact was edited, and no `dev check` or other unscoped full-suite command was run."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}