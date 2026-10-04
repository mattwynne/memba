{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "f0f68f40bf24cfea33abbde6ac8e6bc6b0e3f7d1",
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
      "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008d1",
        "todo_line": "- [ ] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
        "status": "prepared",
        "origin": "Technical prerequisite split from task 008D after direct inspection showed that the existing inner join omits participants without a primary email, preventing complete recipient-eligibility interests.",
        "coverage": [
          "An explicit group-member read mode that includes active participants who currently lack a primary email while retaining their Person and membership identities",
          "The existing recipient-only default result, public map shape, role enrichment and deterministic name/Person ordering remain unchanged",
          "Active group-membership and active club-membership filtering, group isolation and invalid-ID behavior remain unchanged",
          "Focused proof that default reads omit an ineligible participant while the explicit eligibility mode includes that participant with a nil email",
          "A complete technical input for task 008D2 to register exact Person and Person-email interests before either eligibility transition"
        ],
        "replaces": [
          "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008d2",
        "todo_line": "- [ ] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
        "status": "pending",
        "origin": "Remaining message-compose query portion of task 008D after extracting the participant-eligibility read prerequisite into task 008D1.",
        "coverage": [
          "One coherent compose-context result for the selected club and default or explicit audience",
          "Fresh normalized-email identity, active-club authority, current-member resolution and selected-audience participation on every load",
          "Club-member, current-person participating-group and selected-group-member collection interests",
          "Selected Club, selected Group, current membership, current Person and exact group-participation interests",
          "Exact Person and Person-email interests for all active audience participants so both eligibility loss and eligibility gain trigger replacement",
          "Preserved forbidden versus not-found semantics and no ownership of subject, body, validation, retry, send, flash or navigation state"
        ],
        "replaces": [
          "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008e",
        "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
        "status": "pending",
        "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
        "coverage": [
          "One coherent authorized delivery-detail result",
          "Fresh active-club, current-member, group-participation and conversation-access reads",
          "Exact conversation, represented Person, delivery collection and delivery identity interests",
          "Independent MemberEmailDelivery status and MembaStaffEmailDelivery reason convergence",
          "No ownership of route, disclosure, flash or navigation state"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-008f",
        "todo_line": "- [ ] 008F Introduce and focused-test one fresh-authorized invitation context query with club-member collection, current member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
        "status": "pending",
        "origin": "Member-invitation query portion of approved implementation step 4 and the former broad task 008.",
        "coverage": [
          "One coherent invitation context result",
          "Fresh active-club, current-member and manage-members authorization reads",
          "Club-member collection entry and exit for the displayed count",
          "Selected Club, current membership, Person, role and permission interests",
          "No ownership of invitation email, validation, resend decision, delivery feedback or navigation"
        ],
        "replaces": [
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "candidate_origins": []
      },
      {
        "task_id": "task-009",
        "todo_line": "- [ ] 009 Migrate the remaining in-scope member LiveViews to one query-result assign each, preserving routes, access transitions, forms, command state, navigation and UI; ensure delivery status/reason convergence and existing conversation flows do not regress.",
        "status": "pending",
        "origin": "Approved implementation step 5 after dashboard and conversation detail served as the accepted pre-freeze consumers.",
        "coverage": [
          "Group creation, settings, message composition, delivery detail and invitation LiveViews",
          "One coherent result assign per remaining in-scope page",
          "Preserved routes, access transitions, transient state, commands, navigation and UI",
          "Live delivery status and staff-reason convergence",
          "Existing conversation and delivery behavior",
          "No staff stream migration"
        ],
        "replaces": [
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
          "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail proofs, stakeholder scenario, generic lifecycle contract, package extraction, accepted consumer adoption, committed-read-model adapter audit, group-creation query and settings query."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008d1",
          "task-008d2"
        ],
        "scope": "Expose complete audience-participant eligibility inputs, then introduce the fresh-authorized message-compose query with complete scoped and exact interests."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008e",
          "task-008f"
        ],
        "scope": "Introduce the remaining delivery-detail and invitation fresh-authorized query boundaries without absorbing LiveView-owned transient state."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009"
        ],
        "scope": "Migrate the five remaining member LiveViews while preserving routes, access transitions, transient state, commands, navigation, UI and delivery/conversation convergence."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD f0f68f40bf24cfea33abbde6ac8e6bc6b0e3f7d1. The trusted baseline and checked todo preserve task 008C as accepted after its ready-for-review worker result and independent accepting review; no unaccepted candidate origin remains. Direct inspection found that the former task 008D could not satisfy complete recipient-eligibility invalidation as one bounded query-only change: Membership.list_active_members_of_group/1 inner-joins the primary-email row, so a legitimate active group participant without a primary email is absent before the query can register that Person's exact person/person_emails interests. Person notifications contain only person_id and the accepted adapter deliberately has no group-wide fallback, so that participant later gaining a primary email would otherwise leave an open compose result stale. The todo therefore replaces 008D with 008D1, a focused opt-in read-API prerequisite that preserves existing default behavior, and 008D2, the remaining fresh-authorized compose-query obligation including both eligibility directions. All later obligations remain unchanged and both split lines retain lineage to the replaced 008D and its earlier broad origins. The only approved acceptance scenario is already accepted and green and does not cover this technical read-API prerequisite, so scenario_focus is null rather than resetting accepted work or inventing a scenario. Final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "f0f68f40bf24cfea33abbde6ac8e6bc6b0e3f7d1",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008d1-f0f68f4-group-participant-eligibility-1",
    "task_id": "task-008d1",
    "todo_line": "- [ ] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "f0f68f40bf24cfea33abbde6ac8e6bc6b0e3f7d1",
    "outcome": "Extend the existing projected group-member read boundary with an explicit opt-in mode that returns every active participant with a projected Person, including a nil email when no primary-email row exists, while leaving all existing callers on the unchanged recipient-only default and proving both contracts with focused tests.",
    "scope": [
      "Change only `Memba.Membership.list_active_members_of_group` and its focused query tests, using a backward-compatible optional argument such as `include_without_primary_email: true`; keep the existing one-argument call behavior through a default argument.",
      "Replace the unconditional primary-email inner join with query composition that can include an active participant's projected Person and membership identity even when the primary-email row is absent.",
      "For the default call, continue returning only active group participants with a primary email and preserve the existing public map keys `membership_id`, `id`, `name`, `email`, and `roles`.",
      "For the explicit eligibility mode, return every participant whose group membership and matching club membership are active and whose Person projection exists; use the same public map shape and set `email` to nil when no primary-email row exists.",
      "Preserve group isolation, exclusion of inactive group memberships, exclusion of inactive or mismatched club memberships, invalid/unknown group handling, alphabetical name then Person-ID ordering, and active role enrichment.",
      "Add focused cases under the existing `list_active_members_of_group` tests proving that a participant with a projected Person but no primary-email row remains absent by default and appears in explicit eligibility mode with stable membership/Person identity and nil email.",
      "Prove that eligible and ineligible participants are ordered together deterministically in explicit mode, while existing default result shape, role ordering and recipient-only behavior remain unchanged.",
      "Run the existing member-message compose LiveView tests unchanged as regression evidence that its current one-argument call still displays only primary-email-eligible recipient counts."
    ],
    "scope_exclusions": [
      "Do not implement `MembaWeb.MemberMessageComposeQuery`; that is the next split obligation, task 008D2.",
      "Do not change `MembaWeb.MemberMessageLive.New`, its mount, reload, notification, form, send, navigation or rendering behavior.",
      "Do not change `MembaReadModelSource`, its Person invalidations, projector/event contracts or exact matching behavior.",
      "Do not add a club-scoped or group-scoped fallback for Person events.",
      "Do not change recipient eligibility from the existing presence-of-primary-email rule or introduce a new verification policy.",
      "Do not change authoritative command-time recipient resolution in `Memba.Messaging` or `list_active_members_of_group_authoritatively/2`.",
      "Do not expose Ecto projection structs from the Membership public API; retain plain public summary maps.",
      "Do not change group, membership, Person, email-address, role, command, event, projector or database schemas.",
      "Do not edit accepted queries, the generic live-query package, the approved plan, migration matrix, extraction contract, ADRs or acceptance features.",
      "Do not implement tasks 008D2 through 011 or migrate any LiveView.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved technical model requires query interests to cover records that can enter or leave a result and requires app-specific queries to compose authorized read APIs. Message-compose recipient eligibility therefore needs every currently participating Person identity before exact Person notifications can invalidate the future query."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008D1 is now the first unchecked line and is the bounded read-API prerequisite for task 008D2. Accepted lines remain unchanged, and the later query must still supply the complete club, group, membership, represented-Person and both-direction eligibility interests."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted binding baseline preserves all accepted work through task 008C, lists the former 008D line as the next pending obligation, and requires no unaccepted candidate origin to be carried into this implementation attempt."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The MemberMessageLive.New row requires selected-group member collection coverage and represented Persons whose primary-email eligibility changes recipient count. The Person event map emits only exact Person and email-collection identities, while the future compose query must also cover group-member entry and exit."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`list_active_members_of_group/1` currently joins active GroupMembership and Membership rows to Person, then inner-joins a primary PersonEmailAddress. It returns ordered plain maps with membership ID, Person ID, name, email and role names, but the inner join makes participants without a primary email unavailable for interest derivation."
      },
      {
        "path": "web/test/memba/membership/query_test.exs",
        "facts": "The existing `list_active_members_of_group/1` tests establish public summary shape, deterministic ordering, role enrichment, Everyone/Admin group isolation, inactive-membership exclusion and invalid-ID behavior. Extend this focused section rather than creating broad integration fixtures."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/new.ex",
        "facts": "The current compose context calls `Membership.list_active_members_of_group/1` and counts its returned rows, so the one-argument default must remain recipient-only. LiveView wiring, form state and notification replacement are not part of this prerequisite."
      },
      {
        "path": "web/test/memba_web/live/member_message_live/new_test.exs",
        "facts": "Existing regression coverage explicitly proves that a member without a primary-email row is excluded from the displayed recipient count. Those tests should pass unchanged after the opt-in API extension."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Every supported Person event emits exact `{:person, person_id}` and `{:person_emails, person_id}` invalidations without club or group scope. Exact equality matching means task 008D2 can notice a previously ineligible participant gaining an email only if task 008D1 first exposes that participant's Person ID."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps Memba-specific query composition and authorization in the app and requires each query to describe every collection scope and record capable of changing its coherent result."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use focused file-level tests, deterministic database state and normal ExUnit synchronization. Avoid sleeps and unrelated broad test commands."
      }
    ],
    "constraints": [
      "Keep implementation changes limited to `web/lib/memba/membership.ex` and `web/test/memba/membership/query_test.exs`; run the existing LiveView test as unchanged regression evidence.",
      "Use one public group-member query boundary with a backward-compatible default argument rather than duplicating projection SQL in the future web query.",
      "Default options must preserve current behavior exactly: participants without a primary email remain omitted from existing callers.",
      "The explicit mode must distinguish eligibility without changing membership or group authorization semantics; a nil email represents current ineligibility.",
      "Retain plain maps and do not leak Person, PersonEmailAddress, Membership or GroupMembership projection structs.",
      "Preserve deterministic `name` then Person-ID ordering and alphabetically ordered active role names in both modes.",
      "Keep inactive group memberships, inactive club memberships, mismatched membership scope, missing Person projections, other groups and invalid IDs excluded.",
      "Do not infer a new verified-email requirement; preserve the current primary-email-row criterion.",
      "Leave task 008D1 unchecked and return one candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs test/memba_web/live/member_message_live/new_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm implementation changes are limited to `web/lib/memba/membership.ex` and `web/test/memba/membership/query_test.exs`.",
      "Report the final optional API shape and confirm existing one-argument callers retain recipient-only behavior.",
      "Explain how query composition includes a participant without a primary-email row only in explicit eligibility mode while retaining active group and club membership filters.",
      "Report proof that the default call omits a participant without a primary email and the explicit call includes the same membership and Person identity with `email: nil`.",
      "Report proof that eligible and ineligible participants share the existing deterministic ordering and plain-map shape in explicit mode.",
      "Report proof that role enrichment and role ordering remain intact.",
      "Report proof that inactive or mismatched memberships, other groups, missing Person projections and invalid group IDs remain excluded.",
      "Report successful exit status, test count and failure count for the combined focused Membership, no-CRUD-boundary and unchanged compose LiveView regression command.",
      "Report successful format and diff checks.",
      "Confirm no compose query, LiveView wiring, source adapter, package, command-time recipient resolution, projector, projection schema, command, event, plan, matrix, ADR or acceptance feature changed, and task 008D1 remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}