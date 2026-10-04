{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ef0b156a11d5acc055025e43db3438b20e32b35f",
    "accepted_tasks": [
      "- [x] 001 Create the repository migration matrix for every club-member LiveView, recording projection-backed reads, query/result boundaries, existing refresh predicates, fresh authorization and access transitions, event-to-interest mappings (including collection entry/exit, old/new scopes and conservative fallbacks), transient-state exceptions, focused proof and gaps; explicitly inventory the deferred staff streams and other out-of-scope surfaces.",
      "- [x] 003 Introduce and focused-test an app-owned dashboard query/view-model boundary that begins from the authenticated email and fresh active-club authority; move all projection-backed dashboard data behind one coherent socket assign, subscribe before the connected initial read, preserve route/access error semantics and transient LiveView state, and retain the existing notification predicates provisionally.",
      "- [x] 004 Implement and unit-test an app-private provisional binding/source contract for opaque interests, one assign per query, route rebind, relevant refresh, access errors, subscribe-before-read, bind-time reconciliation and reconnect, without a process per query or a frozen package API.",
      "- [x] 005 Wire the dashboard query to the provisional binding and scoped Memba notification translation; prove club-member and selected-group entry/exit, order/count updates, represented Person and role changes, route/access transitions, unrelated-club isolation and transient-state preservation.",
      "- [x] 006 Wire composed conversation detail to the provisional binding; prove Message, represented-Person, exact-follow, both independently committed delivery projections and fresh access-loss behavior, unrelated-conversation isolation and transient-state preservation, then freeze the generic contract from both vertical proofs.",
      "- [x] 006A Implement the approved domain/application scenario “Bob sees Alice join without reloading” against Bob’s already-open club member LiveView, using the committed membership projection notification path and keeping the scenario green.",
      "- [x] 007A Create and document the local Mix package and extract the frozen generic query, source and binding contract into it; give the package self-contained tests for construction, one-owner subscription, interest replacement, invalidation matching, refresh, duplicate/out-of-order notifications, bind/rebind races, reconnect and subscriber cleanup, with no Memba or Commanded imports.",
      "- [x] 007B Replace the dashboard and conversation-detail provisional generic modules with the local package API, keep the Memba notification source and queries in the app, remove the superseded app-private generic contract, and prove both accepted consumers retain their lifecycle, refresh and access-error behavior.",
      "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008b",
        "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "status": "prepared",
        "origin": "Group-creation query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent group-creation context containing only the freshly resolved selected Club and current member",
          "Fresh active-club authority, Person identity, active selected-club membership and manage-members authorization on every load",
          "Exact selected Club, membership, Person, selected-club relationship, active-club collection, current-member role and manage-members permission interests",
          "No ownership of the generated group identity, typed name, preview, validation errors, retry key or command state",
          "Focused descriptor, successful-load, fail-closed freshness and exact-interest tests"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008c",
        "todo_line": "- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
        "status": "pending",
        "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent settings result",
          "Fresh selected-club membership and current-Person resolution",
          "Current Person active-club membership and email-address collections",
          "Selected and represented Club identities",
          "No ownership of tab, add-email form, errors or command feedback"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008d",
        "todo_line": "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
        "status": "pending",
        "origin": "Message-compose query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent compose-context result",
          "Fresh active-club, current-member and selected-audience participation reads",
          "Club-member, participating-group and selected-group-member collection interests",
          "Represented Person and primary-email eligibility interests",
          "No ownership of subject, body, validation, retry or send state"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008e",
        "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
        "status": "pending",
        "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent authorized delivery-detail result",
          "Fresh active-club, current-member, group-participation and conversation-access reads",
          "Exact conversation, represented Person, delivery collection and delivery identity interests",
          "Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence",
          "No ownership of route, disclosure, flash or navigation state"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008f",
        "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "status": "pending",
        "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent invitation context result",
          "Fresh active-club, current-member and manage-members authorization reads",
          "Club-member collection entry and exit for the displayed count",
          "Selected Club, current membership, Person, role and permission interests",
          "No ownership of invitation email, validation, resend decision, delivery feedback or navigation"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
        "status": "pending",
        "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
        "replaces": [
          "- [ ] 006 Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI; ensure list entry/exit and existing live delivery/conversation flows do not regress."
        ],
        "coverage": [
          "Group creation, settings, message composition, delivery detail and invitation LiveViews",
          "One coherent result assign per remaining in-scope page",
          "Preserved routes, access transitions, forms, commands, navigation and UI",
          "Live delivery status and staff-reason convergence",
          "Existing conversation and delivery behavior",
          "No staff stream migration"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
        "status": "pending",
        "origin": "Approved implementation step 6.",
        "replaces": [
          "- [ ] 007 Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments."
        ],
        "coverage": [
          "Path dependency integration in web/mix.exs",
          "Production Docker build and release inclusion",
          "Package tests exercised by dev check in supported environments"
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-011",
        "todo_line": "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
        "status": "pending",
        "origin": "Remainder of approved implementation step 7 after the stakeholder scenario and committed-projector open-LiveView proof were split into accepted task 006A.",
        "replaces": [
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
          "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
        ],
        "coverage": [
          "Focused proof for every migrated member page",
          "Residual package lifecycle and bind/reconnect race coverage",
          "Final full dev check on the exact clean or staged state"
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
          "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract, package extraction, accepted consumer adoption and complete committed-read-model adapter audit."
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
        "scope": "Introduce the five remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing LiveView-owned transient state."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD ef0b156a11d5acc055025e43db3438b20e32b35f. The guard baseline records task 008A as accepted, so its checked todo line is preserved exactly and its former review-revise candidates are accepted history rather than unaccepted candidate origins. Task 008B is now the first unchecked line and is already a bounded query-only prerequisite for the later LiveView migration; todo.md required no edit, split or reorder. Direct inspection confirms the current group-creation LiveView still derives selected Club, current member and manage-members authority from mount-captured clubs in its private group_context/3, while accepted query patterns already provide the generic descriptor shape and the Memba source already provides all required invalidation vocabulary. The prepared packet introduces a separate app-owned query and focused tests only: every load starts from routed club ID and authenticated email, rereads active clubs, resolves the Person and active membership, rechecks manage-members authority, returns one context, and derives the exact nine Club, membership, Person, role and permission interests. LiveView binding, access-error transitions and transient-form preservation remain task 009. The sole approved acceptance scenario is already accepted and green; this technical query-boundary task has no appropriate new scenario-first run. No business decision is needed, there are no unaccepted candidate origins, and final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ef0b156a11d5acc055025e43db3438b20e32b35f",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008b-ef0b156-group-creation-query-1",
    "task_id": "task-008b",
    "todo_line": "- [ ] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "ef0b156a11d5acc055025e43db3438b20e32b35f",
    "outcome": "Introduce one app-owned group-creation context query that freshly resolves the routed Club, authenticated Person, active membership and manage-members authority on every load, returns only the coherent selected-club/current-member result with complete replacement interests, and has focused tests proving its fresh authorization and exact dependency set without wiring or changing the LiveView.",
    "scope": [
      "Add `MembaWeb.MemberGroupCreationQuery` in `web/lib/memba_web/member_group_creation_query.ex`, following the accepted `LiveQuery.Query` descriptor pattern with stable ID `:member_group_creation`, public assign `:group_creation_context`, and inputs containing only `club_id` and `authenticated_email`.",
      "Implement `load/2` so every invocation normalizes the authenticated email, rereads `Accounts.list_active_clubs_for_email/1`, finds the routed selected Club in that fresh set, resolves the current Person with `Membership.get_person_by_email/1`, rereads `Membership.list_active_members_of_club/1`, matches the current member by Person ID, and reruns `Authorization.authorize_manage_members/2`.",
      "Return `{:ok, %{selected_club: selected_club, current_member: current_member}}` only after every fresh authority step succeeds; collapse missing, invalid, inactive, foreign-club and unauthorized inputs to the existing `{:error, :forbidden}` group-creation semantics.",
      "Resolve membership by the freshly resolved Person ID rather than comparing only the member row's primary email, so an authenticated attached email accepted by the existing identity APIs resolves the same current Person and membership.",
      "Derive exactly these nine replacement interests from a successful context: `{:club, club_id}`, `{:membership, membership_id}`, `{:person, person_id}`, `{:person_club, club_id, person_id}`, `{:person_clubs, person_id}`, `{:member_roles, club_id, membership_id, person_id}`, `{:member_permissions, club_id, membership_id, person_id}`, `{:club_roles, club_id}`, and `{:club_permissions, club_id}`.",
      "Add `web/test/memba_web/member_group_creation_query_test.exs` covering the descriptor ID/assign, coherent two-key result, normalized and alternate-email identity resolution, fresh selected-club membership loss, fresh manage-members permission loss, fail-closed invalid inputs, and exact set equality/cardinality for all nine interests.",
      "In the focused tests, prove the result contains no generated group ID, form, typed name, preview, validation, retry or command state, and prove the interests contain no club-member-wide, Group, group-membership, conversation, delivery or generated-future-group dependency.",
      "Run the existing group-creation LiveView tests unchanged as focused regression evidence that introducing the standalone query does not alter current route, form, preview, submit-time authorization or navigation behavior."
    ],
    "scope_exclusions": [
      "Do not wire `MemberGroupLive.New` to `LiveQuery.Binding`; that migration, notification handling and private-surface transition belong to task 009.",
      "Do not change `MemberGroupLive.New.group_context/3`, its mount behavior, render assigns, preview flow, generated group identity, form state, retry behavior, command handling, flash or navigation.",
      "Do not move group-name or email-address preview, name uniqueness, command authorization or aggregate consistency checks into the query.",
      "Do not add `{:club_members, club_id}` merely because the loader uses a member-list API; another member entering or leaving does not alter this result.",
      "Do not add Group, group-membership, message, conversation, follow, delivery or generated future-group interests.",
      "Do not modify `MembaReadModelSource`; its accepted mappings already emit the nine required Club, Membership, Person and Role invalidations.",
      "Do not modify the generic live-query package, dashboard query, conversation-detail query, projectors, projections, commands, event contracts or publishers.",
      "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance features or other iteration documentation.",
      "Do not implement tasks 008C through 011 or migrate any other LiveView.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires every view-specific query to perform a fresh authorized read, return one coherent result plus complete replacement interests, and leave transient UI state with the LiveView. Implementation step 4 owns app-specific authorized queries; step 5 separately owns LiveView migration."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008B is the first unchecked obligation and specifically requires one fresh-authorized group-creation context query with complete Club, member, Person and manage-members interests, independent of transient form state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The binding checkpoint preceding this planner visit accepted task 008A and leaves 008B as the first pending line; no unaccepted candidate origin must be carried into this implementation attempt."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The `MembaWeb.MemberGroupLive.New` entry defines one group-creation result containing freshly authorized selected Club/current member, fresh active-club and manage-members checks, Club/Membership/Person/role/permission dependencies, and explicit exclusion of generated identity, typed input, preview, errors and command state. Its interest matrix includes the current identity's active clubs and selected-club relationship."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "A query has one stable identity and public assign; its one-argument loader returns `{:ok, result, interests}` or `{:error, reason}`, and every success replaces the complete interest set. Access errors and transient owner state remain LiveView responsibilities."
      },
      {
        "path": "web/lib/memba_web/member_dashboard_query.ex",
        "facts": "This accepted app query demonstrates the `LiveQuery.Query.new!/1` descriptor, normalized authenticated-email input, fresh `Accounts.list_active_clubs_for_email/1` authority, coherent result and app-private replacement interests. Its deliberate omission of `person_clubs` is dashboard-specific and does not override the group-creation matrix."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "This second accepted consumer confirms the app query convention: stable query ID and assign, a loader translating successful models to complete interests, and preservation of existing `:forbidden`/`:not_found` semantics."
      },
      {
        "path": "web/lib/memba_web/live/member_group_live/new.ex",
        "facts": "The current private `group_context/3` returns exactly `selected_club` and `current_member`, raises the existing forbidden treatment on context failure, and keeps generated group ID, form, preview, retry and command behavior in the LiveView. It currently receives mount-captured clubs and matches the member by primary email, both of which the standalone fresh query must avoid."
      },
      {
        "path": "web/test/memba_web/live/member_group_live/new_test.exs",
        "facts": "Existing tests protect route and mount authorization, preview behavior, stale-preview command rechecks, technical retries, authorization-state mismatch, submit-time permission loss, generated identity preservation and navigation. Run them unchanged; task 008B does not add open-page binding behavior."
      },
      {
        "path": "web/lib/memba/accounts.ex",
        "facts": "`Accounts.normalize_email/1` and `Accounts.list_active_clubs_for_email/1` provide the normalized identity and current active-club authority that must be reread for every query load."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`Membership.get_person_by_email/1` resolves a Person through projected email-address rows, including an attached authenticated email, while `Membership.list_active_members_of_club/1` returns active member maps with membership ID, Person ID, name, primary email and role labels. Match these reads by Person ID."
      },
      {
        "path": "web/lib/memba/membership/authorization.ex",
        "facts": "`Authorization.authorize_manage_members/2` reads the current projected member permission and returns `:ok` or `{:error, :unauthorized}`; invoke it with the freshly resolved routed club and Person."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted source emits exact `club`, `membership`, `person_club`, `person_clubs`, `member_roles`, `member_permissions`, `club_roles` and `club_permissions` invalidations, while Person notifications emit the represented `person` identity. No adapter change is needed."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps Memba-specific query composition and authorization in the app, returns one coherent view model per query assign, and uses complete interests so relevant committed changes trigger a fresh authorized read."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests should avoid sleeps, use existing deterministic projection and process synchronization patterns, and validate the smallest relevant files before broader checks."
      }
    ],
    "constraints": [
      "Keep the implementation to the new app-owned query module and its focused query test; existing group-creation LiveView tests may be executed but must remain unchanged.",
      "Use only existing read APIs and the accepted `LiveQuery.Query` package API; do not query projection schemas directly from the new query.",
      "Treat routed club ID and authenticated email as stable inputs, but treat active clubs, Person, membership, roles and permission as fresh data on every load.",
      "Return the existing `:forbidden` result for every missing or unauthorized group-creation context; do not invent a new domain or access policy.",
      "Return only `selected_club` and `current_member`; manage-members authorization is a prerequisite, not a display boolean.",
      "Match the current member by freshly resolved Person ID so attached-email authentication remains valid even when the displayed member row contains a different primary email.",
      "Use exact set equality and cardinality to prove all nine interests and prevent accidental broadening or omission.",
      "Include both exact current-member role/permission interests and club-wide role-definition/permission interests because the returned role labels and manage-members permission can change through independently projected role events.",
      "Preserve submit-time aggregate authorization and all existing command consistency behavior; the query does not authorize a later command permanently.",
      "Leave task 008B unchecked and return one candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_group_creation_query_test.exs test/memba_web/live/member_group_live/new_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm they are limited to `web/lib/memba_web/member_group_creation_query.ex` and `web/test/memba_web/member_group_creation_query_test.exs`.",
      "Report the query descriptor ID, public assign and input shape, and show that a successful load returns exactly selected Club and current member.",
      "Explain the fresh read sequence from normalized authenticated email through active clubs, Person, active selected-club membership and manage-members authorization.",
      "Report proof that attached-email authentication resolves the member by Person ID rather than requiring the displayed primary email to equal the sign-in email.",
      "Report proof that selected-club membership deactivation and manage-members permission loss each cause a subsequent load to return `{:error, :forbidden}`.",
      "Report the exact nine-interest set and cardinality, including `person_clubs`, exact member role/permission interests and club-wide role/permission interests.",
      "Confirm the result and interests exclude generated group identity, form/preview/retry/command state, club-member-wide breadth and all Group, messaging and delivery dependencies.",
      "Report successful exit status, test count and failure count for the combined focused query and existing LiveView regression command.",
      "Report successful format and diff checks.",
      "Confirm no LiveView wiring, source adapter, package, projector, projection, command, plan, todo, matrix, ADR or acceptance feature changed, and task 008B remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}