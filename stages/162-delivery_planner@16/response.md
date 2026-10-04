{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "44f459360998660fe0b05df3b6579dfb30ae3688",
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
      "- [x] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
      "- [x] 011A Reconcile classified notifications that arrive while an initial bind or route rebind returns an access error, proving one conservative retry can recover current data while a repeated error leaves the result and interests cleared."
    ],
    "pending_obligations": [
      {
        "task_id": "task-011b",
        "todo_line": "- [ ] 011B Re-run the accepted focused proof for every migrated member page and the package lifecycle/race contract, repair only an observed regression, and run final `dev check` on the exact state.",
        "origin": "The focused consumer-proof and final exact-state validation portion of approved implementation step 7, retained after separating and accepting the concrete bind/rebind error-window lifecycle correction as task 011A.",
        "status": "prepared",
        "coverage": [
          "Re-run focused evidence for all seven migrated club-member LiveViews and their app-owned queries",
          "Re-run the complete generic package lifecycle and race suite, including the accepted task 011A access-error-window cases",
          "Preserve the accepted real committed-projector-to-open-LiveView scenario evidence",
          "Repair only failures observed against approved iteration obligations",
          "Run final full `dev check` on the exact clean worktree or complete staged candidate"
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
          "- [x] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
          "- [x] 011A Reconcile classified notifications that arrive while an initial bind or route rebind returns an access error, proving one conservative retry can recover current data while a repeated error leaves the result and interests cleared."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, seven member LiveView migrations and query boundaries, committed-projector scenario, generic package and adapter, package/release quality-gate integration, and bounded bind/rebind access-error-window reconciliation."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-011b"
        ],
        "scope": "Reconfirm the accepted member-page, app-query, adapter and generic package proofs on the completed implementation, repair only an observed iteration regression, and pass the final exact-state quality gate."
      }
    ],
    "planner_note": "The binding checkpoint for this planner visit is clean HEAD 44f459360998660fe0b05df3b6579dfb30ae3688, not the guard baseline's predecessor. All 22 checked todo lines are preserved exactly. Task 011A has been independently accepted: its latest review confirms focused binding tests, all 19 standalone package tests, package formatting and diff checks passed, with no unaccepted candidate provenance remaining. The sole unchecked obligation is task 011B, whose approved scope is the final focused rerun and exact-state quality gate; no further todo split or edit is needed. The seven migrated member surfaces and their focused proof files were verified directly, and `bin/dev` confirms that full `dev check` runs standalone package tests, web precommit, responsive checks when applicable and browser acceptance. The approved Bob-sees-Alice scenario is already green and accepted under task 006A. Task 011B is therefore a technical final-validation packet rather than a new red scenario-led change, so `scenario_focus` is null; full `dev check` preserves the accepted scenario without reactivating `@wip` or fabricating a failure. No tests were run and no files were edited during this planner visit."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "44f459360998660fe0b05df3b6579dfb30ae3688",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-011b-44f4593-final-proof-1",
    "task_id": "task-011b",
    "todo_line": "- [ ] 011B Re-run the accepted focused proof for every migrated member page and the package lifecycle/race contract, repair only an observed regression, and run final `dev check` on the exact state.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "44f459360998660fe0b05df3b6579dfb30ae3688",
    "outcome": "The completed iteration is reconfirmed by passing focused proof for all seven migrated club-member LiveViews, their app-owned query and notification boundaries, and the full generic package lifecycle/race contract, with any observed iteration regression repaired narrowly and final full `dev check` passing on the exact resulting state.",
    "scope": [
      "Record the starting worktree state and run the complete standalone LiveQuery package test suite, including binding, source, query, reconnect, subscriber-cleanup and accepted task 011A access-error-window cases.",
      "Run the focused LiveView proof for dashboard, group creation, settings, message compose, conversation detail, delivery detail and invitation, including the dashboard committed-projector integration proof.",
      "Run the focused app-owned query and committed-read-model source tests for the seven migrated page boundaries.",
      "If every focused check passes, make no application or test changes and proceed to the final gate.",
      "If a focused check exposes a regression against the approved plan, diagnose it from the concrete failure, make only the smallest implementation or faithful regression-test repair needed, and rerun the affected focused command followed by the complete focused set.",
      "Run full `dev check` as the explicit final-validation obligation, after ensuring the tested state is either a clean worktree or the complete intended candidate staged together.",
      "Return exact commands, exit statuses, test counts, changed paths and final repository-state evidence."
    ],
    "scope_exclusions": [
      "Do not add new product behavior, authorization policy, invalidation vocabulary, projector fallback, package API responsibility, route, UI or stream support.",
      "Do not edit the approved plan, acceptance feature, acceptance rule or example, ADRs, migration matrix, project reference docs or checked todo lines.",
      "Do not reactivate the accepted Bob-sees-Alice scenario as `@wip`, alter its steps or manufacture a new red scenario.",
      "Do not weaken, delete, skip or retag a failing test merely to make the gate pass.",
      "Do not change unrelated code, dependencies, generated artifacts or tooling and do not perform opportunistic cleanup.",
      "Do not substitute `dev check --quick`, `dev ci` or a partial suite for the required final full `dev check`.",
      "Do not claim success if the final gate ran before an unstaged part of the candidate was added or if the worktree changed afterward.",
      "Leave task 011B unchecked and return the evidence for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Implementation step 7 and the validation plan require focused proof per migrated member page, a real committed-projector-to-open-LiveView path, package matching/mount/change/reconnect race coverage, and final full `dev check`. The acceptance contract requires fresh authorization, scoped refresh, transient-state preservation and package independence."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 011B is the first and only unchecked line. It is explicitly the final-validation task and permits only repair of a regression actually observed during the accepted focused reruns."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The inventory identifies exactly seven migrated member LiveView modules and records their query boundaries, fresh authorization, scoped interests, transient state and focused proof. Staff streams and non-member surfaces remain excluded."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen package contract covers one-owner subscription, subscribe-before-read, coherent result and interest replacement, matching-only refresh, rebind, access-error clearing, bind-window reconciliation, reconnect and subscriber cleanup."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture keeps reusable binding in an application-independent local package, keeps Memba queries and notification mapping in the app, refreshes through fresh authorized reads and defers staff streams."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted task 011A and recorded passing focused binding tests, all 19 standalone package tests, package formatting and diff checks. Final `dev check` was deliberately reserved for task 011B."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The accepted task 011A worker changed only the package binding and its focused tests, reported 12 binding tests and 19 complete package tests passing, and left no unresolved items."
      },
      {
        "path": "packages/live_query/test/live_query/binding_test.exs",
        "facts": "The binding suite covers disconnected and connected bind, one shared subscription, relevant-only refresh, atomic interest replacement, duplicate/out-of-order invalidations, route rebind, access-error clearing, successful bind/rebind windows and the accepted bounded access-error-window reconciliation cases."
      },
      {
        "path": "packages/live_query/test/live_query/lifecycle_test.exs",
        "facts": "The lifecycle suite proves a fresh connected owner rereads current state after termination/reconnect and that the source observes subscriber cleanup without sleeps."
      },
      {
        "path": "web/test/memba_web/live/member_dashboard_live_test.exs",
        "facts": "The dashboard focused proof covers member and selected-group entry/exit, ordering and counts, exact Person and role refresh, coherent-result replacement, transient picker preservation, route rebind, fresh access loss, unrelated isolation and conversation entry."
      },
      {
        "path": "web/test/memba_web/live/member_dashboard_admission_live_test.exs",
        "facts": "This file contains the strongest committed-command/projector/PubSub-to-already-open-dashboard integration proof and also exercises current permission refresh."
      },
      {
        "path": "web/test/memba_web/live/member_group_live/new_test.exs",
        "facts": "The group-creation page proof covers relevant and unrelated notifications, coherent context replacement, typed form and validation preservation, and fresh membership or manage-members access loss."
      },
      {
        "path": "web/test/memba_web/live/my_settings_live_test.exs",
        "facts": "The settings proof covers coherent result refresh, tab and form-error preservation, live club-membership chip entry/exit, selected-club access loss and exact Person email-row invalidation."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/new_test.exs",
        "facts": "The compose proof covers audience participant entry/exit, recipient eligibility, exact Club, Group and Person refresh, unrelated isolation, typed-message preservation and fresh audience or club access loss."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/show_test.exs",
        "facts": "The conversation-detail proof covers committed replies, exact represented-author and follow invalidation, unrelated isolation, independent member-status and staff-reason convergence, transient reply/disclosure preservation and fresh access loss."
      },
      {
        "path": "web/test/memba_web/live/member_message_delivery_live/show_test.exs",
        "facts": "The delivery-detail proof covers exact delivery convergence in either projector order, unrelated-message isolation, represented Person refresh, transient route/flash/disclosure preservation and fresh authorization loss."
      },
      {
        "path": "web/test/memba_web/live/member_invitation_live/new_test.exs",
        "facts": "The invitation proof covers member entry/exit, typed input and validation preservation, unrelated-club isolation and fresh membership or manage-members access loss."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "The adapter tests exercise recognized projector and event mappings, exact scoped matching, valid broader scopes, ignored unsupported events and visible malformed-notification contract violations."
      },
      {
        "path": "bin/dev",
        "facts": "Full `dev check` starts required services, performs setup, runs standalone package tests before web precommit, then runs responsive checks when applicable and the browser acceptance suite. `dev test` runs focused web tests with the required test services."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Focused Mix tests should precede broad validation, and any process-test repair must use supervised processes and deterministic message synchronization rather than sleeps or `Process.alive?/1`."
      }
    ],
    "constraints": [
      "Treat the accepted implementation as the baseline; a repair is authorized only after a concrete focused or full-gate failure demonstrates an iteration regression.",
      "Preserve all seven one-query-result boundaries, fresh authorization semantics, invalidation scopes, access transitions and transient LiveView state.",
      "Preserve the generic package's independence from Memba and Commanded, one-owner subscription model and no-process-per-query design.",
      "Preserve the accepted task 011A bound of at most one reconciliation reread for a newly classified bind-window notification.",
      "Keep staff streams, public/auth surfaces and non-LiveView consumers outside iteration 067.",
      "Use the existing focused test files and current public behavior as evidence; do not rewrite tests around implementation details.",
      "Use deterministic process synchronization and do not introduce sleeps.",
      "Before reporting `dev check` as passing, ensure it ran on the exact clean state or on the complete intended diff staged together, and confirm no subsequent file changes invalidated that result.",
      "Do not mark the todo line accepted; independent review owns acceptance."
    ],
    "focused_validation": [
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" test'",
      "dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_dashboard_admission_live_test.exs test/memba_web/live/member_group_live/new_test.exs test/memba_web/live/my_settings_live_test.exs test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/live/member_invitation_live/new_test.exs",
      "dev test test/memba_web/member_dashboard_query_test.exs test/memba_web/member_group_creation_query_test.exs test/memba_web/member_settings_query_test.exs test/memba_web/member_message_compose_query_test.exs test/memba_web/member_message_detail_query_test.exs test/memba_web/member_message_delivery_query_test.exs test/memba_web/member_invitation_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "dev check",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "Report the starting and final `git status --short` output and state whether the final gate ran on a clean worktree or a complete staged candidate.",
      "Report the standalone package command, exit status and exact test/failure count, confirming the accepted task 011A cases and lifecycle tests were included.",
      "Report the focused seven-page LiveView command, exit status and exact test/failure count, identifying the evidence file for each migrated page.",
      "Report the focused app-query and Memba source command, exit status and exact test/failure count.",
      "If any focused or full-gate command initially failed, provide the concrete failure, root cause, changed paths, bounded repair rationale and passing rerun evidence; otherwise explicitly report that no code or test repair was needed.",
      "Report the final full `dev check` command, exit status and its package, web precommit, responsive-check and browser-acceptance outcomes.",
      "Report `git diff --check` and, when a repair exists, staged-diff integrity evidence after the final change.",
      "Confirm the approved Bob-sees-Alice scenario remains enabled and green through the final gate without `@wip` manipulation.",
      "Confirm no plan, feature, ADR, migration matrix, project reference, checked todo line, staff stream or unrelated surface changed.",
      "List every changed path, or explicitly state that this was a validation-only candidate with no changed paths.",
      "Leave task 011B unchecked and return the exact-state evidence for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}