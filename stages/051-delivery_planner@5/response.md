{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "621a5684f40c2b5a0af4f28a85397e942214e7ac",
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
      "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008d2",
        "todo_line": "- [ ] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
        "status": "prepared",
        "origin": "Remaining message-compose query portion of task 008D after extracting and accepting the participant-eligibility read prerequisite as task 008D1.",
        "replaces": [
          "- [ ] 008D Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and recipient-eligibility interests.",
          "- [ ] 008 Complete the Memba adapter for all committed projector mappings and conservative fallbacks in the migration matrix, plus the remaining authorized view-specific queries composed from existing read APIs.",
          "- [ ] 005 Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable."
        ],
        "coverage": [
          "One coherent compose-context result for the selected club and default or explicitly requested audience",
          "Fresh normalized-email identity, active-club authority, current-member resolution and selected-audience participation on every load",
          "Club-member, current-Person participating-group and selected-group-member collection interests",
          "Selected Club, selected Group, current membership, current Person and exact selected-group participation interests",
          "Exact Person and Person-email interests for every active audience participant, including participants currently lacking a primary email, so both recipient-eligibility loss and gain trigger replacement",
          "Recipient count derived only from participants currently possessing a primary email while retaining all participant identities for invalidation",
          "Existing forbidden versus not-found semantics and no ownership of subject, body, validation, retry, send, flash or navigation state"
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
          "Preserved routes, access transitions, transient state, commands, navigation and UI",
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
          "- [x] 008B Introduce and focused-test one fresh-authorized group-creation context query with complete club, member, Person and manage-members interests, composed from existing read APIs and independent of LiveView transient form state.",
          "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
          "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail proofs, stakeholder scenario, generic lifecycle contract, package extraction, accepted consumer adoption, committed-read-model adapter audit, group-creation and settings queries, and the complete audience-participant read prerequisite."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008d2"
        ],
        "scope": "Introduce the fresh-authorized message-compose query with complete selected-context, collection, represented-Person and both-direction recipient-eligibility interests."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 621a5684f40c2b5a0af4f28a85397e942214e7ac. The trusted baseline and checked todo preserve task 008D1 as accepted after its ready-for-review worker result and independent accepting review; the accepted implementation supplies an opt-in group-member read that retains every active participant's Person and membership identity while representing missing primary email as nil, and no unaccepted candidate origin remains. The first unchecked line, task 008D2, is already a bounded query-only change and needs no further todo split. Direct inspection confirms that it can compose existing fresh-authority APIs and the accepted 008D1 read to register exact Person and Person-email interests for both currently eligible and currently ineligible participants, while collection interests cover audience entry and exit. LiveView binding, transient-state preservation under refresh, lifecycle proof and removal of provisional handlers remain in tasks 009 and 011. The only approved acceptance scenario is already accepted and green and does not exercise this standalone query boundary, so scenario_focus is null rather than resetting accepted work or inventing another scenario. Final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "621a5684f40c2b5a0af4f28a85397e942214e7ac",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008d2-621a568-message-compose-query-1",
    "task_id": "task-008d2",
    "todo_line": "- [ ] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "621a5684f40c2b5a0af4f28a85397e942214e7ac",
    "outcome": "Add one app-owned fresh-authorized message-compose live query that returns the existing selected club, current member, audience and primary-email-eligible recipient presentation as one coherent result, while registering complete collection and exact participant interests so both recipient-eligibility loss and gain can invalidate a future open-page binding.",
    "scope": [
      "Add `MembaWeb.MemberMessageComposeQuery` in `web/lib/memba_web/member_message_compose_query.ex` and focused coverage in `web/test/memba_web/member_message_compose_query_test.exs`; follow the accepted app-owned `LiveQuery.Query` descriptor pattern without wiring the LiveView yet.",
      "Give the descriptor stable inputs for routed `club_id`, optional requested `group_id`, and authenticated email, and one compose-context assign containing `selected_club`, `current_member`, `audience_group`, `active_member_count`, and `message_audience` compatible with the current compose presentation.",
      "On every load, normalize the authenticated email, reread `Accounts.list_active_clubs_for_email/1`, resolve the routed club from that fresh set, resolve the current Person by normalized primary or attached email, and resolve the active selected-club membership by Person identity rather than comparing the authenticated address with the primary address.",
      "Reread the current Person's active participating groups, choose the explicit audience or the selected club's Everyone group by default, and preserve the existing distinction: missing or lost club/default-audience authority is `:forbidden`, while an explicitly requested unavailable, unknown, foreign or no-longer-participating group is `:not_found`.",
      "Read selected-audience participants once with `Membership.list_active_members_of_group(group_id, include_without_primary_email: true)`; retain every returned participant for interest derivation while calculating `active_member_count` only from rows whose `email` is non-nil.",
      "Build the audience presentation from the selected club and audience group, preserving the existing club name, group ID/name, singular/plural recipient summary, inbound email address, and the established `active_member_count` field name.",
      "Return interests for selected Club, selected-club member collection, current membership, current Person, exact current-Person club relationship, current-Person participating-group collection, selected Group, selected-group member collection, and exact selected-group participation.",
      "For every active selected-audience participant, including anyone currently lacking a primary email, return both exact `{:person, person_id}` and `{:person_emails, person_id}` interests; deduplicate the complete interest list.",
      "Prove the descriptor and exact coherent result shape, normalized primary and attached-email identity resolution, default and explicit audience selection, fresh authority loss, forbidden/not-found behavior, unrelated club/group isolation, collection interests, and absence of LiveView-owned transient state.",
      "Prove both recipient-eligibility directions: a represented participant losing a primary email lowers the count while retaining exact interests, and a participant whose exact interests were already present before gaining a primary email raises the count after reload.",
      "Prove selected-group participant entry and exit replace represented interests and recipient count without importing unrelated Persons."
    ],
    "scope_exclusions": [
      "Do not change `MembaWeb.MemberMessageLive.New`, bind the new query, replace its ordinary assigns, remove its provisional PubSub handlers, or change mount/reload/send/navigation behavior; those migrations remain in task 009.",
      "Do not add LiveView bind-race, reconnect, form-preservation or navigation tests in this query-only task; remaining lifecycle and page proof belongs to tasks 009 and 011.",
      "Do not change `Memba.Membership.list_active_members_of_group/2`; its opt-in participant contract and default recipient-only behavior were accepted in task 008D1.",
      "Do not duplicate projection SQL in the web query or introduce a new recipient eligibility rule; primary-email presence remains the existing criterion.",
      "Do not expose raw participant email rows or Membership projection structs in the coherent public result solely to derive interests.",
      "Do not change command-time recipient resolution in `Memba.Messaging` or `list_active_members_of_group_authoritatively/2`.",
      "Do not change `MembaReadModelSource`, add broad Person fallbacks, or alter projector, event, projection, schema or notification contracts.",
      "Do not add role, permission, message, conversation, follow or delivery interests that do not contribute to the compose context.",
      "Do not implement delivery-detail, invitation, package-integration, final-proof or any other later todo obligation.",
      "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved model requires each view-specific query to return one coherent authorized result plus every collection and represented-record interest capable of changing it. Refreshes must use fresh authority, and LiveView-owned forms, commands and navigation remain outside the query."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008D2 is the first unchecked line. It is the remaining compose-query obligation after accepted task 008D1 exposed all active audience participants independently of current primary-email eligibility."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint preserves every checked line through 008D1, identifies 008D2 as the first pending obligation, and requires no unaccepted candidate origin to be carried into this packet."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The accepted 008D1 worker result added an opt-in `include_without_primary_email: true` mode while retaining the one-argument recipient-only default and reported focused Membership and unchanged compose regression tests passing."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted 008D1's stable plain-map shape, nil-email representation, active group and club membership filters, deterministic ordering, role enrichment and unchanged default behavior; 008D2 may rely on that accepted read boundary."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The MemberMessageLive.New row requires one selected-club/audience result, fresh active-club and group-participation checks, selected-group member collection coverage, represented Persons whose primary-email eligibility affects count, preserved forbidden/not-found transitions, and no ownership of subject/body/send/retry state."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`list_active_members_of_group/2` now returns all otherwise eligible active selected-group participants when `include_without_primary_email: true`, preserving Person and membership IDs and using `email: nil` when the primary-email row is absent. Existing APIs also provide fresh Person, club-member and participating-group reads."
      },
      {
        "path": "web/lib/memba_web/live/member_message_live/new.ex",
        "facts": "The current private compose loader selects the routed club, current member and requested/default group, distinguishes explicit missing groups as not found from default authority failures as forbidden, counts primary-email-eligible group members, and builds the five-field compose presentation. Its form, send, retry, flash and navigation state must remain outside the new query."
      },
      {
        "path": "web/lib/memba_web/member_group_creation_query.ex",
        "facts": "This accepted query demonstrates the app-owned `LiveQuery.Query` descriptor pattern, normalized-email fresh club authority, current Person/member resolution by Person ID, fail-closed access results and explicit interest construction."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "This accepted composed query demonstrates stable routed inputs, one coherent result, replacement interests, exact current membership and Person authority, and `:forbidden | :not_found` propagation without importing LiveView state."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Membership notifications emit club-member, exact membership and exact person-club keys; GroupMembership notifications emit selected-group member, current-Person group collection and exact participation keys; Person-family notifications emit only exact Person and Person-email keys. The query must therefore register every currently ineligible participant before that Person gains an email."
      },
      {
        "path": "web/test/memba/membership/query_test.exs",
        "facts": "Accepted focused tests prove the opt-in participant read includes no-primary-email Persons with stable identities and nil email while retaining active membership scope, isolation, ordering, roles, invalid-ID handling and unchanged default omission."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps Memba-specific authorization and query composition in the app and requires each query to describe collection scopes and records capable of changing its coherent result."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use focused file-level ExUnit coverage and deterministic synchronization; avoid sleeps, broad unrelated commands and implementation patterns that violate the project Elixir guidance."
      }
    ],
    "constraints": [
      "Keep implementation changes limited to the new compose-query module and its focused test file; use existing public context APIs and accepted query patterns.",
      "Resolve the current member through the normalized email's Person identity and an active selected-club member row so attached-email authentication does not depend on the member summary's primary email.",
      "Use one all-participant read per load as the source of both recipient count and participant interests so those outputs cannot diverge within a successful result.",
      "Count only non-nil primary-email rows; do not use the audience group's projected `active_member_count`, which includes participants who are currently ineligible recipients.",
      "Register exact Person and Person-email interests for eligible and ineligible participants before filtering for count.",
      "Preserve the current default-Everyone and explicit-group forbidden/not-found distinction.",
      "Return plain result data and opaque interest tuples; do not leak Ecto projection structs.",
      "Exclude form, validation, send/retry, flash, route and navigation state from the query result.",
      "Deduplicate interests and exclude unrelated club, group and Person identities.",
      "Leave task 008D2 unchecked and return one candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_message_compose_query_test.exs test/memba/membership/query_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm implementation changes are limited to `web/lib/memba_web/member_message_compose_query.ex` and `web/test/memba_web/member_message_compose_query_test.exs`.",
      "Report the final descriptor ID, assign and stable input shape, plus the exact coherent result keys.",
      "Explain how every load normalizes identity, rereads active clubs, resolves Person and current member by Person ID, and rechecks selected-group participation.",
      "Report proof that default Everyone and explicit group selection preserve the existing forbidden versus not-found behavior.",
      "List the complete successful-result interest set and explain how each collection or exact identity maps to a current source invalidation.",
      "Report proof that participants without a primary email contribute exact Person and Person-email interests while remaining absent from the recipient count.",
      "Report proof that primary-email loss decreases the count without losing that participant's interests and primary-email gain increases the count from interests present before eligibility.",
      "Report proof that group-participant entry and exit replace represented interests and count while unrelated club/group Persons remain absent.",
      "Confirm the result contains no subject, body, form, validation, compose/send/retry, flash, route or navigation state.",
      "Report successful exit status, test count and failure count for the combined focused query and Membership command.",
      "Report successful format and diff checks.",
      "Confirm no LiveView wiring, adapter, package, Membership API, authoritative recipient resolution, projector, schema, command, event, plan, todo, matrix, ADR, acceptance feature or delivery metadata changed, and task 008D2 remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}