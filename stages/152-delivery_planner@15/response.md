{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "91505d37a9ce1e2c266277ab36f0440ebed9bc17",
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
      "- [x] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks.",
      "- [x] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
      "- [x] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
      "- [x] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments."
    ],
    "pending_obligations": [
      {
        "task_id": "task-011a",
        "todo_line": "- [ ] 011A Reconcile classified notifications that arrive while an initial bind or route rebind returns an access error, proving one conservative retry can recover current data while a repeated error leaves the result and interests cleared.",
        "origin": "The residual package lifecycle and bind-window race portion of approved implementation step 7. Direct inspection found that successful initial binds and rebinds reconcile classified notifications delivered during their read windows, while the corresponding error branches return immediately without reconciliation.",
        "status": "prepared",
        "coverage": [
          "Initial connected bind retries once when a classified notification arrives while the first query read returns an access error",
          "Route rebind retries once against the new inputs when a classified notification arrives while the first rebind read returns an access error",
          "A successful retry installs the current coherent result and complete interests",
          "A retry that still fails returns the final access error and leaves the public result and interests cleared",
          "No notification or an unclassified notification preserves the original error behavior without an extra read",
          "Bind-window notification consumption remains bounded and cannot create a retry loop"
        ],
        "replaces": [
          "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
          "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-011b",
        "todo_line": "- [ ] 011B Re-run the accepted focused proof for every migrated member page and the package lifecycle/race contract, repair only an observed regression, and run final `dev check` on the exact state.",
        "origin": "The focused consumer-proof and final exact-state validation portion of approved implementation step 7, retained after separating the concrete bind/rebind error-window lifecycle defect into task 011A.",
        "status": "pending",
        "coverage": [
          "Re-run focused evidence for all seven migrated club-member LiveViews and their app-owned queries",
          "Re-run the complete generic package lifecycle and race suite after task 011A",
          "Preserve the accepted real committed-projector-to-open-LiveView scenario evidence",
          "Repair only failures observed against approved iteration obligations",
          "Run final full `dev check` on the exact clean worktree or complete staged diff"
        ],
        "replaces": [
          "- [ ] 011 Close the remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`.",
          "- [ ] 008 Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.",
          "- [ ] 011 Implement the approved Bob-sees-Alice-join acceptance example, close remaining focused proof gaps for every migrated member page, complete package lifecycle/race coverage, and run final `dev check`."
        ],
        "candidate_origins": []
      }
    ],
    "candidate_origins": [],
    "coverage_map": [
      {
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic package extraction, committed-read-model adapter, app-owned query prerequisites, all seven member LiveView migrations, and package build/quality-gate integration.",
        "pending_task_ids": [],
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
          "- [x] 009C Migrate `MembaWeb.MemberMessageLive.New` to its accepted compose-context query-result assign, preserving route/audience semantics, typed message form, validation, send/retry state, navigation and UI while refreshing recipient eligibility and counts with fresh access checks.",
          "- [x] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors.",
          "- [x] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
          "- [x] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments."
        ]
      },
      {
        "scope": "Close the remaining generic package bind-window race when the first initial-bind or route-rebind read returns an access error.",
        "pending_task_ids": [
          "task-011a"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Reconfirm accepted member-page and package proof on the completed implementation and run the final exact-state quality gate.",
        "pending_task_ids": [
          "task-011b"
        ],
        "accepted_task_lines": []
      }
    ],
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 91505d37a9ce1e2c266277ab36f0440ebed9bc17, not the guard baseline's predecessor. All 21 checked todo lines, including independently accepted task 010, are preserved exactly and there is no unaccepted candidate provenance. Direct inspection of the accepted page tests shows that tasks 005, 006 and 009A through 009E already provide the required focused evidence for every migrated member page, while accepted task 007A covers ordinary successful bind/rebind races, fresh-owner reconnect and subscriber cleanup. One residual package case remains: LiveQuery.Binding reconciles classified bind-window notifications only after a successful first read; its initial-bind and route-rebind error branches return immediately, so a notification crossing an access-error read cannot conservatively recover current state. The former task 011 was therefore split into bounded task 011A for that package correction and task 011B for exact-state focused reruns and final dev check. Both children explicitly retain the replaced task-011 lineage. The approved Bob-sees-Alice scenario is already green and accepted under task 006A; task 011A is generic technical lifecycle work with no appropriate new scenario, so scenario_focus is null. No dev check was run for this planner-only todo edit."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "91505d37a9ce1e2c266277ab36f0440ebed9bc17",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-011a-91505d3-bind-error-reconcile-1",
    "task_id": "task-011a",
    "todo_line": "- [ ] 011A Reconcile classified notifications that arrive while an initial bind or route rebind returns an access error, proving one conservative retry can recover current data while a repeated error leaves the result and interests cleared.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "91505d37a9ce1e2c266277ab36f0440ebed9bc17",
    "outcome": "A connected initial bind or route rebind that receives a classified source notification during an access-error read performs exactly one conservative reread: a now-authorized result is installed with its complete interests, while a repeated error is returned as the final outcome with the result and interests still cleared.",
    "scope": [
      "Add focused package tests for an initial connected bind whose first loader call delivers a classified notification and returns an access error, then whose single reconciliation read succeeds with current result and interests.",
      "Add focused package tests for a route rebind whose first read of the new inputs delivers a classified notification and returns an access error, then whose single reconciliation read succeeds and supersedes the old route result and interests.",
      "Prove the bounded failure case: when the reconciliation read also returns an access error, return that final error, keep the query's public assign nil and interests empty, consume the crossing notification, and do not retry again.",
      "Prove that an error read with no newly classified notification preserves the existing one-read error behavior.",
      "Adjust `LiveQuery.Binding` so bind-window classification can determine the outcome after either a successful or failed first read while reusing the existing generic notification classification and forced-query refresh responsibilities.",
      "Keep the successful bind/rebind reconciliation behavior and all ordinary notification refresh behavior unchanged."
    ],
    "scope_exclusions": [
      "Do not change Memba queries, notification keys, projector mapping, authorization policy, LiveViews, routes, UI or member-page tests.",
      "Do not edit acceptance features or step definitions, and do not reactivate the already-accepted Bob-sees-Alice scenario.",
      "Do not introduce repeated retries, polling, sleeps, a process per query, durable notification claims or a global cache.",
      "Do not broaden the package API or expose Memba- or Commanded-specific concepts from the generic package.",
      "Do not change access-error navigation or rendering policy; the LiveView owner continues to decide how a final query error is handled.",
      "Do not add unrelated defensive API tests or refactor the package beyond what is needed for the error-window reconciliation contract.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full repository suite during this worker visit; task 011B owns final exact-state validation and the deterministic workflow owns its post-worker gate.",
      "Leave task 011A unchecked and return the bounded candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The technical model requires a notification received across the first read and interest-installation window to trigger conservative reconciliation. The validation plan requires relevant bind-time races while preserving fresh authorization and clearing private data on access failure."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 011A is the first unchecked obligation and isolates the remaining error-window lifecycle case. Task 011B separately retains all accepted focused-proof reruns and final full dev check."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract says a connected bind subscribes before its first read, notifications delivered across the bind window are reconciled, rebind replaces inputs/result/interests, and failed reads clear the public result and interests before returning the error to the owner."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture assigns subscription ownership to the LiveView and requires relevant committed changes to trigger fresh authorized reads without patching fields from events."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "`bind/4` and `rebind/3` currently call `reconcile_bind_window/3` only from the successful `read_and_install/2` branch. Their error branches return immediately after installing a registration with an empty interest set, so a classified notification delivered during that failed read cannot force the current reread."
      },
      {
        "path": "packages/live_query/test/live_query/binding_test.exs",
        "facts": "Existing tests prove successful bind-window and rebind-window reconciliation and ordinary bind/rebind/refresh error clearing, but do not combine a crossing notification with a first read that returns an error."
      },
      {
        "path": "packages/live_query/lib/live_query/query.ex",
        "facts": "A generic query loader returns either a coherent result with its complete opaque interests or an error. The correction must preserve this public result contract."
      },
      {
        "path": "packages/live_query/lib/live_query/source.ex",
        "facts": "The source owns generic subscription, notification classification and opaque interest matching. Error-window reconciliation must continue using these callbacks without importing application concepts."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Process tests must use supervised processes and message synchronization rather than sleeps or `Process.alive?/1`; focused Mix tests should be used before broader validation."
      }
    ],
    "constraints": [
      "Subscribe before the connected initial read and retain one shared source subscription per LiveView owner.",
      "Only messages newly delivered after the bind or rebind mailbox snapshot may participate in that window's reconciliation.",
      "Only notifications successfully classified by the source trigger the conservative reread; pre-existing and ignored messages must retain their existing handling.",
      "Perform at most one reconciliation reread for the captured window. Notifications generated by that reread must not create an inline retry loop.",
      "When the reconciliation reread succeeds, atomically install its result and complete interests and return success rather than the stale first error.",
      "When the reconciliation reread fails, return its final error with the public result nil and interests empty; never resurrect old route data or old interests.",
      "When no classified notification crossed the window, preserve the original first-read error and read count.",
      "Preserve existing successful bind/rebind behavior, relevant-only ordinary refresh, duplicate/out-of-order handling and transient socket assigns.",
      "Keep the package independent of Memba and Commanded and create no additional runtime process.",
      "Use deterministic mailbox assertions and existing test helpers; do not use timing sleeps."
    ],
    "focused_validation": [
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" test test/live_query/binding_test.exs'",
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" test'",
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" format --check-formatted'",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and explain how it contributes specifically to bind/rebind error-window reconciliation or its focused proof.",
      "Report the initial focused test failure before the implementation change, including the concrete assertion or unexpected stale error that demonstrated the gap.",
      "Report focused tests proving initial-bind recovery, route-rebind recovery, repeated-error clearing and no-notification one-read behavior.",
      "Report the binding test file command, exit status and exact test/failure count.",
      "Report the complete standalone package test command, exit status and exact test/failure count.",
      "Report package formatting and `git diff --check` exit statuses.",
      "Confirm each crossing window performs no more than one reconciliation reread and that the notification is consumed.",
      "Confirm a final error leaves the public assign nil and interests empty, while a successful retry installs only the new result and interests.",
      "Confirm no Memba application code, LiveView, feature, step definition, plan, ADR, migration matrix, delivery metadata or task 011B scope was changed.",
      "Leave task 011A unchecked and return the candidate for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}