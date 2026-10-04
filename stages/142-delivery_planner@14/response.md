{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b851f0a8a8a3315f462fb0c95cfcd2d32c32e30",
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
      "- [x] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access."
    ],
    "pending_obligations": [
      {
        "task_id": "task-010",
        "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
        "origin": "Approved implementation step 6.",
        "status": "prepared",
        "coverage": [
          "Preserve and verify the existing `web/mix.exs` local path dependency",
          "Make the local package available before Docker dependency resolution and compilation",
          "Include the compiled LiveQuery OTP application in the production release",
          "Fetch the package's standalone locked dependencies through the supported development setup",
          "Run the package's own tests as part of the standard `dev check` precommit path",
          "Preserve web precommit, browser acceptance and quality-gate failure propagation",
          "Exercise the package integration in local devenv and CI-supported workflows"
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
          "Residual package lifecycle, bind-window and reconnect race coverage",
          "Final full `dev check` on the exact clean or staged state"
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
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, all app-owned query prerequisites, and every in-scope member LiveView migration.",
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
          "- [x] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access."
        ]
      },
      {
        "scope": "Complete local path-dependency, production release, Docker-context and standard quality-gate integration for the accepted LiveQuery package.",
        "pending_task_ids": [
          "task-010"
        ],
        "accepted_task_lines": []
      },
      {
        "scope": "Close residual per-page and package lifecycle proof gaps and run final exact-state validation.",
        "pending_task_ids": [
          "task-011"
        ],
        "accepted_task_lines": []
      }
    ],
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 0b851f0a8a8a3315f462fb0c95cfcd2d32c32e30, not the baseline artifact's predecessor. All checked todo lines, including independently accepted task 009E, are preserved exactly. The existing task 010 and 011 split still accounts for every remaining approved obligation, so todo.md required no edit. Task 010 is the first unchecked line and remains one bounded build-and-quality-gate integration slice: `web/mix.exs` already declares the accepted path dependency, but the Docker builder copies only the web manifests before dependency resolution and never copies `packages/live_query`, while `bin/dev` setup and precommit currently prepare and test only the web project. The packet therefore preserves the accepted package API and consumers while fixing Docker/release inclusion, standalone package dependency setup, package-test execution through `dev check`, and focused orchestration regressions. Task 011 continues to own residual behavior/lifecycle proof and the final full exact-state `dev check`. There is no unaccepted candidate provenance. The sole approved acceptance scenario is already green and accepted under task 006A; package/build integration is explicit technical work with no appropriate new scenario, so scenario_focus is null."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b851f0a8a8a3315f462fb0c95cfcd2d32c32e30",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-010-0b851f0-package-build-gate-1",
    "task_id": "task-010",
    "todo_line": "- [ ] 010 Complete package integration with `web/mix.exs`, the production Docker build/release and `dev check` so package and web tests run in supported environments.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "0b851f0a8a8a3315f462fb0c95cfcd2d32c32e30",
    "outcome": "The accepted local LiveQuery path dependency resolves and compiles in the production Docker/release layout, the resulting release contains the LiveQuery OTP application, and the supported `dev check` path prepares and runs the package's standalone tests as well as the existing web and acceptance gates with failures propagated correctly.",
    "scope": [
      "Preserve the existing `{:live_query, path: \"../packages/live_query\"}` dependency in `web/mix.exs`; change it only if focused dependency or release proof exposes a concrete integration defect.",
      "Adjust the production Docker builder layout or copy ordering so the repository-relative LiveQuery path project exists before web `mix deps.get`, its production configuration and library source exist before `mix deps.compile`, and the runner copies the release from the corresponding final builder path.",
      "Keep package tests, test support and package-only test configuration out of the production release. Avoid copying generated package `_build`, `deps`, coverage or documentation artifacts into the Docker context or image; update `.dockerignore` or use narrowly scoped `COPY` instructions as appropriate.",
      "Teach the supported `bin/dev` setup path to fetch the standalone package's locked dependencies in addition to the web dependencies, with package setup failures returned immediately.",
      "Teach the standard precommit path used by `dev check` to run the package in `packages/live_query` as its own Mix project, then retain the existing web precommit behavior. Ensure a package failure cannot be masked by a later successful web command while `with_quality_gate_lock/1` is operating under `set +e`.",
      "Use a checkout-local, project-aware way to invoke the real Mix executable for the package. Do not let the repository `bin/mix` wrapper or devenv's web-oriented `mix` convenience function silently redirect package commands into `web`.",
      "Update the directly affected shell regression harnesses, or add one focused harness, to prove package tests and web precommit are both invoked from the current checkout, package failure prevents a false-green quality gate, and existing checkout/devenv isolation remains intact.",
      "If package dependency/build caches are retained by CI, include the package lockfile and package build/dependency directories consistently without changing the semantics of `devenv test` or `dev check`.",
      "Produce a local production release and verify its `lib` directory contains `live_query-0.1.0/ebin/live_query.app`. If a Docker daemon is available, additionally build the actual image and inspect the same application file in the runtime image; otherwise report the unavailable Docker CLI explicitly and return the local release plus Docker copy-order evidence.",
      "Keep package and web lockfiles independently authoritative: standalone package checks use `packages/live_query/mix.lock`, while the parent production release resolves through `web/mix.lock`."
    ],
    "scope_exclusions": [
      "Do not change the accepted LiveQuery query, source or binding API or its runtime semantics.",
      "Do not add the residual lifecycle, reconnect or bind-window coverage owned by task 011.",
      "Do not modify member queries, the Memba notification adapter, LiveViews, projectors, domain behavior, routes or UI.",
      "Do not edit acceptance features, step definitions, the approved plan, todo, migration matrix, extraction contract, ADRs or delivery metadata.",
      "Do not publish the package to Hex, introduce an umbrella, add a process per query or move Memba-specific code into the package.",
      "Do not opportunistically upgrade, align or regenerate unrelated package or web dependencies; preserve the two existing lockfile boundaries unless a required integration command makes a minimal lock correction unavoidable and explain it.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` scenario; it is accepted under task 006A and does not exercise package/build integration.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full application suite during this worker visit. The deterministic workflow owns its post-worker gate, and task 011 retains final exact-state validation.",
      "Leave task 010 unchecked and return the integration candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Approved implementation step 6 requires the local package to integrate with `web/mix.exs`, the production Docker release and `dev check`; acceptance criteria require the production release to include the package and the quality gate to execute its tests."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 010 is the first unchecked obligation. Task 011 separately retains residual focused proof, package lifecycle/race coverage and final full `dev check`."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "The accepted architecture places the reusable binding in a local Mix path-dependency package independent of Memba and Commanded, and explicitly records build and test integration as a consequence."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The accepted package boundary is represented by `LiveQuery.Query`, `LiveQuery.Source` and `LiveQuery.Binding`; package tests lock the frozen subscription, refresh, rebind, reconciliation, reconnect and cleanup semantics. This task integrates that contract without redesigning it."
      },
      {
        "path": "web/mix.exs",
        "facts": "The web project already declares `{:live_query, path: \"../packages/live_query\"}` as a normal runtime dependency. Its `precommit` alias compiles, checks unused dependencies, formats and runs only the web project's test alias; dependency tests are not automatically executed."
      },
      {
        "path": "packages/live_query/mix.exs",
        "facts": "LiveQuery is an independent OTP application with its own dependency graph, lockfile and test-only `test/support` compilation path. Its tests must run from this project rather than being treated as web test files."
      },
      {
        "path": "packages/live_query/README.md",
        "facts": "The package is application-independent and owns only generic query, source and binding responsibilities; Memba authorization, invalidation vocabulary and projector mapping must remain outside it."
      },
      {
        "path": "packages/live_query/test/live_query/binding_test.exs",
        "facts": "The standalone package tests cover disconnected and connected binding, one-owner subscription, relevant-only refresh, atomic result/interest replacement, duplicate and out-of-order notifications, access-error clearing and bind/rebind reconciliation."
      },
      {
        "path": "packages/live_query/test/live_query/lifecycle_test.exs",
        "facts": "Lifecycle proof uses a package-owned Phoenix endpoint and test support to verify fresh connected mounts, reconnection-style owner replacement and subscriber cleanup, confirming why the package must be tested in its own Mix project."
      },
      {
        "path": "Dockerfile",
        "facts": "The builder currently works at `/app`, copies only `web/mix.exs` and `web/mix.lock`, then runs `mix deps.get` and `mix deps.compile`. From that manifest the accepted path dependency resolves to `/packages/live_query`, which is never copied, so the current production image cannot resolve or compile it."
      },
      {
        "path": ".dockerignore",
        "facts": "Docker context exclusions cover web build/dependency artifacts but do not currently cover corresponding `packages/live_query` artifacts that standalone package setup and tests can generate."
      },
      {
        "path": "bin/dev",
        "facts": "`_setup/0` currently fetches only web dependencies, `_precommit/0` runs only web `mix precommit`, and `_check/0` delegates to those before browser acceptance. `with_quality_gate_lock/1` temporarily disables immediate shell exit, so newly sequenced package and web commands must explicitly preserve failures."
      },
      {
        "path": "bin/mix",
        "facts": "The checkout-local Mix wrapper deliberately resolves the real executable and always changes into `web`; invoking it after `cd packages/live_query` would still run the wrong project unless the integration adds an explicit project-aware path."
      },
      {
        "path": "devenv.nix",
        "facts": "Both the devenv `mix` script and interactive shell convenience function are web-oriented, while `devenv test` invokes `bin/dev setup` followed by `bin/dev check`. Package invocation must bypass or safely generalize the web-only convenience without breaking existing callers."
      },
      {
        "path": ".fabro/workflows/scripts/test_dev_checkout_boundary.sh",
        "facts": "The existing focused shell harness models only a web checkout and currently expects one web `precommit` invocation. It must be adapted if `bin/dev` starts invoking a second Mix project, while preserving foreign-checkout isolation assertions."
      },
      {
        "path": ".fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh",
        "facts": "This regression proves `_ci` and `_check` stop after a precommit failure and preserve its status. New package-before-web sequencing needs equivalent proof that a package failure is not masked."
      },
      {
        "path": ".github/workflows/continuous-delivery.yml",
        "facts": "CI runs `devenv test`, so correct `bin/dev` integration reaches CI automatically. Existing caches include web dependencies/builds but neither package paths nor `packages/live_query/mix.lock` in the cache key."
      },
      {
        "path": "docs/reference/project-guidelines.md",
        "facts": "The repository quality gate is full `dev check`, which runs Mix precommit/ExUnit and browser acceptance. This worker should add package execution to that path while leaving the deterministic post-worker node to run the unscoped gate."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Mix tasks should be inspected and focused tests should be used for diagnosis; broad dependency cleaning is discouraged. The package and parent project should retain their independent project and lockfile boundaries."
      }
    ],
    "constraints": [
      "Preserve every accepted implementation and the package's frozen generic/Memba separation.",
      "Package tests must execute as the `packages/live_query` Mix project with its own lockfile, test configuration and support modules.",
      "Web application compilation and release resolution continue to use the web project's dependency graph and lockfile.",
      "The package setup/test command and existing web precommit must each propagate non-zero status immediately; do not rely on ambient `set -e` inside the quality-gate lock wrapper.",
      "Docker dependency manifests must be available before `mix deps.get`, and package production source must be available before `mix deps.compile`.",
      "Production Docker instructions must not depend on package test support or generated local package artifacts.",
      "Keep local, CI and nested-devenv checkout isolation intact; do not resolve Mix from a foreign Memba checkout.",
      "Do not require PostgreSQL for standalone package tests, which exercise a package-owned endpoint and in-memory collaborators.",
      "Do not claim an actual Docker image build if no Docker-compatible daemon is available in the worker sandbox; distinguish local production-release proof from image proof.",
      "Keep the change bounded to package/build/quality-gate integration and directly affected focused shell regressions."
    ],
    "focused_validation": [
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" deps.get; \"$package_mix\" test'",
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'package_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd packages/live_query; \"$package_mix\" format --check-formatted'",
      "bash .fabro/workflows/scripts/test_dev_checkout_boundary.sh && bash .fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh",
      "env -u MEMBA_DEVENV_SHELL devenv shell -- bash -lc 'web_mix=\"$(dirname \"$(command -v elixir)\")/mix\"; cd web; MIX_ENV=prod \"$web_mix\" deps.get --only prod; MIX_ENV=prod \"$web_mix\" release --overwrite; test -f _build/prod/rel/memba/lib/live_query-0.1.0/ebin/live_query.app'",
      "bash -n bin/dev && git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and explain how each change contributes to Docker/release inclusion, package setup, quality-gate execution or its focused regression proof.",
      "Report the standalone package test command, exit status and exact test/failure count, confirming it ran from `packages/live_query` rather than `web`.",
      "Report focused shell-regression exits demonstrating that package and web checks both run from the current checkout and that a failing package check cannot be masked by a successful later command.",
      "Report the production release command and the exact `live_query-0.1.0/ebin/live_query.app` path found in the assembled release.",
      "If Docker is available, report the image build command, exit status and runtime-image inspection of the LiveQuery application file. If unavailable, record the missing tool/daemon explicitly and provide the local release proof plus the Docker manifest/source copy ordering used.",
      "Confirm package tests and test support are excluded from production inputs and generated package build/dependency artifacts are excluded from the Docker context or narrowly bypassed.",
      "Confirm the existing web path dependency and independent package/web lockfile boundaries were preserved, with any unavoidable manifest or lockfile change called out precisely.",
      "Confirm no LiveQuery behavior, Memba application behavior, LiveView, feature, plan, todo, ADR or delivery-artifact change was made.",
      "Return all focused validation exit statuses and `git diff --check` evidence, leaving task 010 unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}