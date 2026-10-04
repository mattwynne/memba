{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "34a236d87416549adc94294e30e69037ead93f5f",
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
      "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008c",
        "todo_line": "- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
        "status": "prepared",
        "origin": "Settings-query portion of approved implementation step 4 and the former broad task 008.",
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent settings result containing selected Club, current Person, active club-membership rows and email-address rows",
          "Fresh normalized-email identity, active-club authority, current-Person resolution and selected-club membership on every load",
          "Current Person active-club and email-address collection interests",
          "Exact current Person, selected-club relationship, selected Club and every represented Club identity",
          "No ownership of tab routing, add-email form contents, errors, command feedback, flash or navigation",
          "Focused descriptor, coherent-result, fresh-loss, interest-replacement and fail-closed tests"
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
          "- [x] 008A Complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks in the corrected migration matrix. Preserve exact scoped matching and ignore unrelated projectors; surface known malformed Membership notifications with unrecoverable person identity as contract violations rather than fallback refreshes. Audit remaining fallbacks against real current/legacy event shapes and obtain a fresh independent review.",
          "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail proofs, stakeholder scenario, generic lifecycle contract, package extraction, accepted consumer adoption, committed-read-model adapter audit and group-creation query boundary."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008c",
          "task-008d",
          "task-008e",
          "task-008f"
        ],
        "scope": "Introduce the four remaining fresh-authorized one-result query boundaries from existing read APIs without absorbing LiveView-owned transient state."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 34a236d87416549adc94294e30e69037ead93f5f. The trusted baseline and todo now preserve task 008B as accepted after its successful independent review; its candidate work is accepted evidence and no unaccepted candidate origin remains. Task 008C is the first unchecked line and is already a bounded query-only prerequisite, so todo.md required no split, reorder or edit. Direct inspection confirms MySettingsLive currently loads four projection-backed assigns before subscribing, refreshes only email rows through a hand-written Person-event predicate, and relies on mount-time selected-club authority. The prepared packet adds a standalone app-owned settings query and focused tests only: each load starts from routed club ID and authenticated email, freshly resolves active-club authority and current Person, verifies the selected club remains in that Person's active membership rows, loads all active club-membership and email rows, and derives exact Person, Person-email, Person-clubs, selected relationship and represented Club interests. LiveView binding, access-error navigation, one-assign rendering and transient-form preservation remain task 009. The only approved acceptance scenario is already accepted and green and does not cover this technical query-boundary prerequisite, so scenario_focus is null rather than fabricating a new scenario or resetting accepted work. Final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "34a236d87416549adc94294e30e69037ead93f5f",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008c-34a236d-settings-query-1",
    "task_id": "task-008c",
    "todo_line": "- [ ] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "34a236d87416549adc94294e30e69037ead93f5f",
    "outcome": "Introduce one app-owned settings query that freshly resolves selected-club authority and the current Person on every load, returns one coherent four-field settings model with complete replacement interests for membership, email and represented-Club changes, and has focused tests without wiring or changing MySettingsLive.",
    "scope": [
      "Add `MembaWeb.MemberSettingsQuery` in `web/lib/memba_web/member_settings_query.ex`, following the accepted `LiveQuery.Query` descriptor pattern with stable ID `:member_settings`, public assign `:settings`, and inputs containing only `club_id` and `authenticated_email`.",
      "Implement the loader so every invocation normalizes the authenticated email, rereads `Accounts.list_active_clubs_for_email/1`, resolves the routed selected Club from that fresh set, resolves the current Person with `Membership.get_person_by_email/1`, and then rereads `Membership.list_active_club_memberships_for_person/1` and `Membership.list_person_email_addresses/1`.",
      "Require the selected club to remain represented in the freshly loaded active club-membership rows for the resolved Person. Return the existing `{:error, :forbidden}` settings semantics for missing, invalid, inactive, foreign-club or unresolved identity contexts.",
      "Return exactly one coherent map with keys `selected_club`, `current_person`, `current_person_clubs`, and `current_person_email_addresses`, preserving the shapes and stable ordering supplied by the existing context APIs.",
      "Derive replacement interests containing `{:person, person_id}`, `{:person_emails, person_id}`, `{:person_clubs, person_id}`, `{:person_club, selected_club_id, person_id}`, and one deduplicated `{:club, club_id}` for the selected Club and every Club represented by `current_person_clubs`.",
      "Do not add exact membership interests for every row: every valid membership entry or exit already emits the Person-wide `person_clubs` collection key, while `person_club` separately represents selected-club authority. Do not add the broader `club_members` collection because another Person joining a represented club cannot change this settings result.",
      "Add `web/test/memba_web/member_settings_query_test.exs` covering descriptor ID/assign, the exact four-key coherent result, normalized and attached-email identity resolution, multiple active club rows and email rows, fresh removal of a non-selected club with interest replacement, fresh selected-club membership loss, fail-closed invalid inputs, and exact set equality/cardinality for the complete interests.",
      "In focused tests, prove represented Club interests update as the active-club collection changes, selected-club loss returns `{:error, :forbidden}`, and neither the result nor interests contain tab, add-email form, validation/error, command, flash, navigation, Group, messaging, delivery, role or permission state.",
      "Run the existing MySettingsLive tests unchanged as regression evidence that adding the standalone query does not alter current routes, tab patches, email commands, hand-written notification behavior or rendering."
    ],
    "scope_exclusions": [
      "Do not wire `MySettingsLive` to `LiveQuery.Binding`; one-result assignment, notification replacement and access-error transition belong to task 009.",
      "Do not change `MySettingsLive.mount/3`, `handle_params/3`, `handle_info/2`, event handlers, render assigns, tab routing, email forms, validation state, command feedback, flash or navigation.",
      "Do not remove or rewrite the current hand-written `ReadModelChanges` subscription and Person-event predicate in this query-only task.",
      "Do not move email-address commands, verification delivery, form normalization or command authorization into the query.",
      "Do not add `club_members`, Group, group-membership, role, permission, message, conversation, follow or delivery interests.",
      "Do not modify `MembaReadModelSource`; its accepted Club, Membership and Person mappings already emit every required settings invalidation.",
      "Do not modify the generic live-query package, accepted dashboard/group-creation/conversation-detail queries, projectors, projections, commands, event contracts or publishers.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or other iteration documentation.",
      "Do not implement tasks 008D through 011 or migrate any LiveView.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires each view-specific query to return one coherent result and complete replacement interests, perform fresh authorization on every read, and leave transient UI state and access-error navigation with the LiveView. Implementation step 4 owns app-specific authorized queries; step 5 separately owns LiveView migration."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008C is the first unchecked obligation and specifically requires a fresh-authorized settings query covering selected Club, current Person, active club memberships, email rows and complete identity and collection interests."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The binding checkpoint records task 008B as accepted and leaves task 008C first in `pending_before`; no unaccepted candidate origin must be carried into this implementation attempt."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The MySettingsLive entry defines one settings model containing selected Club, current Person, current active club memberships and email-address rows. It requires fresh authenticated-email and selected-club authority, Person-wide active-club and email collections, selected and represented Club identities, selected-club membership authority, and exclusion of tab/form/error/feedback state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "A query has one stable ID and public assign; its loader returns `{:ok, result, interests}` or `{:error, reason}`, and each success replaces the complete result and interest set. A failed read clears only the query result, while forms, routes, flash and navigation remain owner responsibilities."
      },
      {
        "path": "web/lib/memba_web/live/my_settings_live.ex",
        "facts": "The current LiveView independently assigns `selected_club`, `current_person`, `current_person_clubs` and `current_person_email_addresses`; reads selected Club and Person before subscribing; refreshes only email rows for matching Person events; and separately owns active tab, add-email form/error, commands, feedback and rendering."
      },
      {
        "path": "web/test/memba_web/live/my_settings_live_test.exs",
        "facts": "Existing regression coverage protects profile/club/email rendering, route-backed tab selection, email command flows and exact-Person notification isolation. These tests should run unchanged; open-page migration and new lifecycle proofs remain later obligations."
      },
      {
        "path": "web/lib/memba_web/member_group_creation_query.ex",
        "facts": "The newly accepted adjacent query demonstrates the app convention for a `LiveQuery.Query.new!/1` descriptor, normalized authenticated-email input, fresh active-club and Person resolution, coherent result, forbidden collapse and app-private replacement interests."
      },
      {
        "path": "web/lib/memba/accounts.ex",
        "facts": "`Accounts.normalize_email/1` rejects non-binary and blank values, and `Accounts.list_active_clubs_for_email/1` returns the current active Club projections for the authenticated email. The selected routed Club must be resolved from this fresh list on every load."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`Membership.get_person_by_email/1` resolves primary or attached email addresses to the Person; `list_active_club_memberships_for_person/1` returns ordered membership rows with membership and represented Club data; and `list_person_email_addresses/1` returns the ordered primary/alternate email rows required by settings."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted adapter emits `club` for Club changes; `membership`, `person_club` and `person_clubs` for every valid membership entry/exit; and both `person` and `person_emails` for every supported Person event. Exact tuple matching means the proposed settings interests refresh only the affected Person or represented Club."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps Memba-specific query composition and authorization in the app, binds one coherent view model to one assign, and refreshes from projections when a complete query interest matches a committed notification."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused tests should use deterministic projection updates and process synchronization, avoid sleeps, and validate the smallest relevant files before broader checks."
      }
    ],
    "constraints": [
      "Keep implementation changes to the new app-owned settings query module and its focused query test; existing MySettingsLive tests may be executed but must remain unchanged.",
      "Use only existing read APIs and the accepted `LiveQuery.Query` package API; do not query projection schemas from the production query module.",
      "Treat routed club ID and authenticated email as stable inputs, but treat active clubs, Person identity, memberships, represented Clubs and email rows as fresh data on every load.",
      "Preserve the current settings access contract by returning only `{:error, :forbidden}` for missing or unauthorized context; do not invent a new domain or access policy.",
      "Resolve current Person through the normalized authenticated email so an attached email recognized by the existing identity APIs maps to the same Person and settings data.",
      "Verify selected-club membership against the fresh active membership rows before returning a result, so a partially stale or foreign selected Club cannot retain private settings data.",
      "Use exact set equality and cardinality in focused tests, including deduplication when the selected Club also appears among represented active clubs.",
      "Use `person_clubs` for active membership collection entry/exit, `person_emails` for email-row replacement, exact `person` for displayed Person data, exact `person_club` for selected-club authority, and exact `club` for each represented Club.",
      "Preserve all existing email command behavior and authorization; a successful query read does not authorize later commands permanently.",
      "Leave task 008C unchecked and return one candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_settings_query_test.exs test/memba_web/live/my_settings_live_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm they are limited to `web/lib/memba_web/member_settings_query.ex` and `web/test/memba_web/member_settings_query_test.exs`.",
      "Report the query descriptor ID, public assign and input shape, and show that a successful result has exactly `selected_club`, `current_person`, `current_person_clubs` and `current_person_email_addresses`.",
      "Explain the fresh read sequence from normalized authenticated email through active clubs, selected Club, current Person, active membership rows and email rows.",
      "Report proof that normalized attached-email authentication resolves the same current Person and settings data.",
      "Report proof that a non-selected active membership entering or leaving changes the result and represented Club interests on the next load.",
      "Report proof that selected-club membership loss causes a subsequent load to return `{:error, :forbidden}`.",
      "Report the exact interest set and cardinality for a result with at least two active clubs, including `person`, `person_emails`, `person_clubs`, selected `person_club` and deduplicated represented `club` identities.",
      "Confirm the result and interests exclude tab, add-email form/error, command, flash, navigation, club-member-wide, Group, role, permission, messaging and delivery state.",
      "Report successful exit status, test count and failure count for the combined focused query and unchanged MySettingsLive regression command.",
      "Report successful format and diff checks.",
      "Confirm no LiveView wiring, source adapter, package, accepted query, projector, projection, command, plan, todo, matrix, ADR or acceptance feature changed, and task 008C remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}