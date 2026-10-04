{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "94fa7d7ac2e6b0ec6a4749382091831ea4f93e76",
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
      "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests."
    ],
    "pending_obligations": [
      {
        "task_id": "task-008e",
        "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
        "status": "prepared",
        "origin": "Delivery-detail query portion of approved implementation step 4 and the former broad task 008.",
        "coverage": [
          "One coherent authorized delivery-detail result containing only projection data justified by the delivery surface",
          "Fresh normalized-email active-club, current-member, group-participation and conversation-access checks on every load",
          "Exact selected Club, current membership, current Person, selected-club relationship, conversation, access, requested/root message and represented-Person interests",
          "Exact root-message delivery collection and represented delivery identity interests matching both independently committed delivery projector families",
          "Member-facing status and staff-facing reason convergence under repeated fresh reads",
          "Preserved forbidden versus not-found semantics and no ownership of route, disclosure, flash or navigation state"
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
          "- [x] 008C Introduce and focused-test one fresh-authorized settings query for selected club, current Person, active club memberships and email rows, with complete identity and collection interests.",
          "- [x] 008D1 Extend and focused-test the Membership group-member read API so callers can obtain every active audience participant's Person identity independently of primary-email eligibility, while preserving its existing recipient-only behavior and ordering by default.",
          "- [x] 008D2 Introduce and focused-test one fresh-authorized message-compose context query for the selected club and audience, with complete club, group, membership, represented-Person and both-direction recipient-eligibility interests."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, generic lifecycle contract and package extraction, committed-read-model adapter audit, and the accepted group-creation, settings, audience-participant and message-compose query prerequisites."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008e"
        ],
        "scope": "Introduce the fresh-authorized delivery-detail query with exact access, represented-Person and independently committed member-status/staff-reason delivery interests."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-008f"
        ],
        "scope": "Introduce the remaining fresh-authorized invitation query boundary without absorbing LiveView-owned transient state."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 94fa7d7ac2e6b0ec6a4749382091831ea4f93e76. The trusted baseline and checked todo preserve task 008D2 as accepted after its ready-for-review worker result and independent accepting review; no unaccepted candidate origin remains. The first unchecked line, task 008E, is already a bounded query-only change and needs no todo rewrite or further split. Direct inspection confirms that the accepted fresh-authorized conversation-detail loader, current delivery presentation, and audited source adapter provide a narrow implementation path: expose one delivery-specific result, omit conversation/follow and LiveView transient state, and register the exact access, represented-Person, root-message delivery collection and delivery identities matched by both delivery projector families. LiveView binding, subscribe-before-read behavior, open-page status/reason convergence, disclosure preservation and access-loss navigation remain in tasks 009 and 011. The only approved acceptance scenario is already accepted and green and does not exercise this standalone delivery-query boundary, so scenario_focus is null rather than resetting accepted work or inventing a scenario. Final full dev check remains explicitly covered by task 011."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "94fa7d7ac2e6b0ec6a4749382091831ea4f93e76",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-008e-94fa7d7-delivery-detail-query-1",
    "task_id": "task-008e",
    "todo_line": "- [ ] 008E Introduce and focused-test one fresh-authorized delivery-detail query with exact conversation, access, represented-Person and independently committed member-status/staff-reason delivery interests.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "94fa7d7ac2e6b0ec6a4749382091831ea4f93e76",
    "outcome": "Add one app-owned fresh-authorized delivery-detail live query that returns only the coherent message metadata and member receipt presentation needed by the delivery surface, while registering exact conversation/access, represented-Person, root-message delivery-collection and delivery-identity interests so either independently committed member-status or staff-reason projection can invalidate a future open-page binding.",
    "scope": [
      "Add `MembaWeb.MemberMessageDeliveryQuery` in `web/lib/memba_web/member_message_delivery_query.ex` and focused coverage in `web/test/memba_web/member_message_delivery_query_test.exs`; follow the accepted app-owned `LiveQuery.Query` descriptor pattern without wiring the LiveView yet.",
      "Give the descriptor stable `club_id`, `message_id`, and `authenticated_email` inputs, a distinct delivery-detail query ID, and one `:delivery_detail` result assign.",
      "Compose the accepted fresh-authorized message-detail read boundary or its existing public collaborators so every load normalizes the authenticated email, rereads active clubs, resolves the current Person and active selected-club membership, resolves the conversation audience, and rechecks authoritative conversation access.",
      "Preserve the existing access contract: missing or inactive selected-club authority is `:forbidden`; missing, foreign-club, inaccessible or otherwise unavailable messages are `:not_found`.",
      "Project one delivery-specific result containing the selected Club, current member, requested message metadata, conversation/audience identity, sender presentation, root delivery-message identity, presented receipts, delivery IDs, receipt count, summary and grouped rows needed by the existing delivery surface.",
      "Exclude conversation entries, follow state and raw joined delivery projection records from the public delivery result; derive exact interests without exposing unrelated conversation-detail data.",
      "Return interests for the selected Club, current membership, current Person, exact selected-club Person relationship, exact current-Person group participation, exact conversation and conversation access, the requested message and root message when distinct, and the root message's delivery collection.",
      "Return exact `{:delivery, delivery_id}` interests for every represented receipt and exact `{:person, person_id}` interests for the displayed sender and represented recipients; deduplicate the complete interest set.",
      "Prove the root-message delivery scope is retained when the routed message is a reply, while the coherent result still presents the routed message metadata and the existing back-to-conversation identity.",
      "Prove representative valid notifications from both `MemberEmailDelivery` and `MembaStaffEmailDelivery` intersect the same exact-message delivery query interests, while a delivery notification for another message does not.",
      "Prove fresh reloads observe member-facing status and staff-facing reason independently and converge after each contributor changes, without relying on projector commit order.",
      "Prove normalized primary or attached-email identity resolution, fresh membership/access loss, represented sender/recipient interests, exact unrelated-message isolation, zero-recipient presentation, and absence of LiveView-owned route, disclosure, flash and navigation state."
    ],
    "scope_exclusions": [
      "Do not change `MembaWeb.MemberMessageDeliveryLive.Show`, bind the new query, replace ordinary assigns, remove provisional PubSub handling, or change mount, refresh, rendering or navigation behavior; those migrations remain in task 009.",
      "Do not add subscribe-before-read, bind-race, reconnect, browser disclosure-state or open-LiveView delivery-refresh tests in this query-only task; remaining lifecycle and page proof belongs to tasks 009 and 011.",
      "Do not change the accepted `MembaWeb.MemberMessageDetailQuery` public contract or weaken its conversation, follow, message-author or delivery interests.",
      "Do not copy projection SQL into the new query or introduce a new delivery-status/reason merge rule; use the existing joined `Messaging.list_member_email_deliverys/1` and presentation semantics through the accepted read boundary.",
      "Do not expose raw `MemberEmailDelivery` or `MembaStaffEmailDelivery` projection structs in the new coherent result solely to derive interests.",
      "Do not change `MembaWeb.LiveQuery.MembaReadModelSource`, projector handlers, event shapes, projections, schemas, webhook behavior or committed notification contracts.",
      "Do not add broad club, group, Person or global delivery fallbacks; use the adapter's existing exact `message_deliveries` and `delivery` invalidations.",
      "Do not treat replay-only `EmailDeliveryOpened` as a status/reason change.",
      "Do not implement invitation, remaining LiveView migration, package integration, final proof or any later todo obligation.",
      "Do not edit the approved plan, todo, migration matrix, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` acceptance scenario.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and explicit final-validation task own the iteration-wide gate."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "The approved model requires each view-specific query to return one coherent authorized result and every collection or represented-record interest capable of changing it. Delivery status and staff reason are independently committed contributors, and fresh authorization must run on every refresh."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 008E is the first unchecked line and asks only for the fresh-authorized delivery-detail query plus focused tests; LiveView migration, package integration and final proof remain later obligations."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/_guard/planner-guard-baseline.json",
        "facts": "The trusted checkpoint preserves every checked line through task 008D2, identifies 008E as the first pending obligation, and requires no unaccepted candidate origin to be carried into this packet."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json",
        "facts": "The latest worker result completed only the message-compose query candidate, reported its bounded two-file change and focused checks passing, and left no unresolved item relevant to the delivery query."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/.delivery/latest-review.json",
        "facts": "Independent review accepted task 008D2 and confirmed that no candidate provenance remains; delivery-detail task 008E is therefore the next implementation rather than a revision."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The delivery-detail row requires one authorized delivery model with exact conversation/access, represented author/recipient, root-message delivery collection and delivery identity interests. Both delivery projectors must independently trigger rereads, while route, native disclosure, flash and navigation state stay in the LiveView."
      },
      {
        "path": "web/lib/memba_web/member_message_detail_query.ex",
        "facts": "The accepted conversation-detail query already normalizes email, rereads active-club authority through `MemberMessageDetail.load/3`, propagates forbidden/not-found results, and demonstrates exact membership, Person, group-participation, conversation, access, message and delivery interest construction."
      },
      {
        "path": "web/lib/memba_web/member_message_detail.ex",
        "facts": "The shared loader resolves the current Person/member, message club ownership, authoritative conversation access and root conversation, then joins member delivery status with staff reason and builds the existing receipt count, summary and groups. Its full result also contains conversation/follow data that the delivery-specific query must not expose."
      },
      {
        "path": "web/lib/memba_web/live/member_message_delivery_live/show.ex",
        "facts": "The current delivery surface renders selected club/current member, routed message metadata, sender name, receipt count, summary and grouped receipt rows. Route params, back-link context, native disclosure behavior, flash and navigation remain LiveView-owned and are excluded from this query-only task."
      },
      {
        "path": "web/lib/memba/messaging.ex",
        "facts": "`list_member_email_deliverys/1` reads member receipt rows for one message and left-joins the separately committed staff delivery projection by delivery ID, so a fresh reread after either projector commits yields the latest joined status/reason state."
      },
      {
        "path": "web/lib/memba_web/member_email_delivery_presentation.ex",
        "facts": "The established presentation converts joined receipts into member-facing receipt rows, total count, ordered summary and non-empty groups, including safe zero-recipient percentages and staff reason text only for delivery problems."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "Both MemberEmailDelivery and MembaStaffEmailDelivery valid change events classify to `{:message_deliveries, message_id}` and `{:delivery, delivery_id}`; replay-only EmailDeliveryOpened is ignored, and malformed or unsupported events are surfaced rather than broadened."
      },
      {
        "path": "web/test/memba_web/member_message_detail_query_test.exs",
        "facts": "Accepted focused tests demonstrate the descriptor pattern, fresh normalized authority, forbidden transition, conversation/access interests, represented authors, exact delivery IDs and replacement interests."
      },
      {
        "path": "web/test/memba_web/live/member_message_delivery_live/show_test.exs",
        "facts": "Current page tests lock the existing message metadata, delivery status/reason presentation, zero-recipient model, reply back-link behavior and access-loss navigation; live delivery-projector refresh is intentionally still a later migration/proof gap."
      },
      {
        "path": "web/test/memba_web/live_query/memba_read_model_source_test.exs",
        "facts": "The adapter audit proves both delivery projector families emit identical exact message/delivery invalidations for valid status/reason events, ignore complete EmailDeliveryOpened events, reject malformed delivery payloads and isolate unrelated query interests."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture keeps authorized Memba query composition in the app, places only generic binding mechanics in the local package, and requires one coherent result assign whose matching committed changes trigger a fresh read."
      },
      {
        "path": "docs/reference/elixir-mix-tests.md",
        "facts": "Use focused file-level ExUnit coverage and deterministic synchronization; avoid sleeps, broad unrelated commands and implementation patterns that violate the project Elixir guidance."
      }
    ],
    "constraints": [
      "Keep implementation changes limited to `web/lib/memba_web/member_message_delivery_query.ex` and `web/test/memba_web/member_message_delivery_query_test.exs`; compose accepted public query/read APIs rather than modifying existing consumers.",
      "Use a stable descriptor with one result assign and a one-argument loader returning `{:ok, result, interests}` or the existing access error.",
      "Every read must start from the authenticated email and fresh active-club authority; never use mount-captured `current_identity_clubs` or a previously assigned member.",
      "Preserve the existing `:forbidden` versus `:not_found` distinction exactly.",
      "Treat the conversation root ID as the delivery collection scope even when the routed message is a reply; retain exact requested-message identity separately.",
      "Register exact sender and receipt-recipient Person interests and exact represented delivery IDs, with deterministic deduplication.",
      "Use the same exact `message_deliveries` and `delivery` interests for both delivery projector families; do not encode projector modules into the query.",
      "Return a delivery-specific plain result and omit conversation entries, follow state, raw joined delivery records and all LiveView transient state.",
      "Leave task 008E unchecked and return one candidate for independent review."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/member_message_delivery_query_test.exs test/memba_web/member_message_detail_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List all changed paths and confirm implementation changes are limited to `web/lib/memba_web/member_message_delivery_query.ex` and `web/test/memba_web/member_message_delivery_query_test.exs`.",
      "Report the final descriptor ID, assign and stable input shape, plus the exact coherent delivery-result keys.",
      "Explain how every load normalizes identity, rereads active clubs, resolves the current Person/member and rechecks conversation audience/access.",
      "Report proof that forbidden versus not-found behavior remains unchanged for inactive authority, missing messages, foreign-club messages and lost conversation access.",
      "List the complete successful-result interest set and explain how Club, membership, Person, group-participation, conversation/access, message, message-delivery and delivery identities map to current source invalidations.",
      "Report proof that sender and receipt recipients contribute exact Person interests and that unrelated Persons and deliveries are absent.",
      "Report proof that a routed reply still uses the root conversation's delivery collection and preserves the routed message presentation.",
      "Report proof that representative valid MemberEmailDelivery and MembaStaffEmailDelivery notifications both match the query while an unrelated message delivery does not.",
      "Report proof that repeated fresh reads converge member status and staff reason when those contributors change independently, including zero-recipient behavior.",
      "Confirm the result contains no conversation entries, follow state, raw delivery projection records, route params, disclosure, flash or navigation state.",
      "Report successful exit status, test count and failure count for the combined focused query, accepted detail-query and source-adapter command.",
      "Report successful format and diff checks.",
      "Confirm no LiveView wiring, adapter, existing query contract, projector, schema, command, event, plan, todo, matrix, ADR, acceptance feature or delivery metadata changed, and task 008E remains unchecked for independent review."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}