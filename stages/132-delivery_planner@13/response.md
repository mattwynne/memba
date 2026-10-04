{
  "execution_state": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7cb6a786217ba052ac62fba2df415b169168534b",
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
      "- [x] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
    ],
    "pending_obligations": [
      {
        "task_id": "task-009e",
        "todo_line": "- [ ] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
        "origin": "Member-invitation page slice of approved implementation step 5 after the dashboard and conversation-detail consumers proved and froze the binding contract.",
        "status": "prepared",
        "coverage": [
          "One coherent invitation-context query-result assign for `MembaWeb.MemberInvitationLive.New`",
          "Subscribe-before-read handling of committed selected-club membership, Club, Person and manage-members invalidations",
          "Selected-club member-count entry and exit refreshes",
          "Fresh selected-club membership and manage-members authorization on initial load, relevant refresh and pre-command reconciliation",
          "Preserved group-aware return routes, invitation form and validation, resend and delivery feedback, command state, flash, navigation and UI",
          "Unrelated-club isolation and no staff or stream-backed surface changes"
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
        "origin": "Approved implementation step 6.",
        "status": "pending",
        "coverage": [
          "Path-dependency integration in `web/mix.exs`",
          "Production Docker build and release inclusion",
          "Package tests exercised by `dev check` in supported environments"
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
          "- [x] 009D Migrate `MembaWeb.MemberMessageDeliveryLive.Show` to its accepted delivery-detail query-result assign, preserving routes, disclosure state, access transitions, navigation and UI while converging exact-message member status and staff reason updates from independently committed projectors."
        ],
        "pending_task_ids": [],
        "scope": "Accepted migration inventory, dashboard and conversation-detail vertical proofs, stakeholder scenario, frozen generic package contract, committed-read-model adapter audit, all app-owned query prerequisites, and completed group-creation, settings, message-compose and delivery-detail LiveView migrations."
      },
      {
        "accepted_task_lines": [],
        "pending_task_ids": [
          "task-009e"
        ],
        "scope": "Migrate member invitation to its accepted live-query result while preserving return routes, form, resend, delivery feedback, command behavior and fresh authorization."
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
    "planner_note": "The binding checkpoint for this planner visit is current HEAD 7cb6a786217ba052ac62fba2df415b169168534b. All checked todo lines, including newly accepted task 009D, remain preserved exactly. The existing 009E, 010 and 011 split still accounts for every remaining approved obligation, so todo.md required no edit. Task 009E is the first unchecked line and is bounded around one LiveView whose fresh-authorized query, interests and source mappings are already accepted. The packet installs that query as the sole projection-backed result, handles relevant notifications, proves count refresh, access loss, isolation and transient-state preservation, and requires a pre-command rebind because `Membership.invite_club_member/2` is explicitly actor-neutral and requires member-facing callers to authorize before dispatch. There is no unaccepted candidate provenance to carry forward. The plan's sole acceptance scenario is already green and accepted under task 006A and does not specifically exercise the invitation migration, so scenario_focus is null rather than reactivating it. Explicit bind-window/reconnect gap closure and the final full `dev check` remain accounted for by task 011, while the deterministic workflow owns the iteration-wide quality gate after this worker."
  },
  "planner_result": {
    "schema_version": 1,
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7cb6a786217ba052ac62fba2df415b169168534b",
    "decision": "ready"
  },
  "current_worker_packet": {
    "schema_version": 1,
    "packet_id": "task-009e-7cb6a78-invitation-binding-1",
    "task_id": "task-009e",
    "todo_line": "- [ ] 009E Migrate `MembaWeb.MemberInvitationLive.New` to its accepted invitation-context query-result assign, preserving group-aware return routes, invitation form/validation, resend and delivery feedback, command state, navigation and UI while refreshing member counts and fresh manage-members access.",
    "attempt": "implementation",
    "plan_path": "docs/iterations/067-live-projection-queries/plan.md",
    "todo_path": "docs/iterations/067-live-projection-queries/todo.md",
    "source_baseline": "7cb6a786217ba052ac62fba2df415b169168534b",
    "outcome": "`MembaWeb.MemberInvitationLive.New` obtains all projection-backed invitation context through its accepted `:invitation_context` live query, updates an already-open member count on relevant committed changes, leaves or clears the private surface on fresh access loss, and preserves invitation form, resend, delivery-feedback, route and navigation behavior.",
    "scope": [
      "In `MembaWeb.MemberInvitationLive.New`, initialize route parameters and invitation form/error state before binding `MemberInvitationQuery.query/0` with the routed club ID and `socket.assigns.current_identity_email` through `MembaReadModelSource.new/0`.",
      "Use the accepted query's single public `:invitation_context` result assign as the only projection-backed source for selected club, current member and active-member count; remove the duplicate mount-time `invitation_context/3` read and its mount-captured active-club authorization helpers.",
      "Render from the coherent invitation context, flattening it only into render-local assigns if useful. Do not restore independent socket assigns for `selected_club`, `current_member` or `active_member_count`.",
      "Handle committed read-model notifications through `Binding.handle_notification/2`: ignore unrelated notifications, keep successful replacements bounded to `:invitation_context`, and make unexpected binding/source failures visible.",
      "Preserve the existing initial forbidden behavior. On a delivered relevant membership, role or permission change that makes the fresh query return `:forbidden`, use the existing forbidden/private-surface treatment after the binding has cleared the stale query result.",
      "Before dispatching `Membership.invite_club_member/2`, rebind task `:member_invitation` with the stable routed club and authenticated email so this member-facing caller freshly authorizes the actor before invoking the actor-neutral invitation lifecycle. On rebind authorization failure, do not create, resend or deliver an invitation.",
      "After a successful pre-command rebind, retain the current invitation normalization, pending/resend decision, strong-consistency dispatch, email delivery, success/error flash and form-reset/retry behavior, reading the selected club from the coherent result.",
      "Add focused LiveView proof that selected-club member entry and exit notifications replace the coherent result and update `data-active-member-count` on an already-open invitation page.",
      "Add focused proof that a relevant context refresh preserves typed email input and validation errors, while an unrelated-club notification neither reloads the invitation context nor disturbs transient form and route state.",
      "Add focused proof that delivered current-member membership loss and manage-members loss leave the already-open private surface using fresh authorization and that submit-time reauthorization prevents the actor-neutral invitation command after projected authority has been lost.",
      "Keep existing routed mount, selected-group return links, email-only form, invite/resend, delivery feedback, active-member rejection, signed-out return path, navigation and UI tests green."
    ],
    "scope_exclusions": [
      "Do not change the accepted `MembaWeb.MemberInvitationQuery`, its interest vocabulary, the generic LiveQuery package, `MembaReadModelSource`, projectors, event structs, schemas, routes or domain authorization policy unless a concrete blocker is returned for replanning.",
      "Do not add a second projection-backed result assign, manual PubSub subscription, page-specific projector predicate, event-driven field patch or broad fallback invalidation.",
      "Do not move invitation form values, validation errors, flash, resend/delivery feedback, route parameters or command retry state into the query result.",
      "Do not change invitation business rules, token lifecycle, email content, duplicate handling, visual design, URLs or selected-group return behavior.",
      "Do not migrate staff invitations or any other staff, public, auth, onboarding or stream-backed surface.",
      "Do not edit the approved plan, todo, migration matrix, extraction contract, ADRs, acceptance features or delivery metadata.",
      "Do not reactivate or rerun the already-green `Bob sees Alice join without reloading` scenario; it is accepted under task 006A and is not the focused boundary for this migration.",
      "Do not add the residual explicit bind-window or reconnect coverage owned by task 011 unless implementation exposes a specific invitation-only defect that blocks this migration.",
      "Do not implement package/Docker/quality-gate integration owned by task 010.",
      "Do not run `dev check`, `dev check --quick`, `dev ci` or another unscoped full-suite command; the deterministic workflow and final-validation obligation own the iteration-wide gate.",
      "Leave task 009E unchecked and return the candidate for independent review."
    ],
    "references": [
      {
        "path": "docs/iterations/067-live-projection-queries/plan.md",
        "facts": "Approved implementation step 5 requires each in-scope member LiveView to use one query-result assign while preserving routes, access transitions, forms, command state, navigation and UI. Relevant invalidations must trigger fresh authorized reads without patching fields from events."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/todo.md",
        "facts": "Task 009E is the first unchecked obligation. Its invitation-query prerequisite is accepted; package integration and final residual proof remain separate later tasks."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/migration-matrix.md",
        "facts": "The invitation row specifies one context containing selected club/member and active-member count, club-member collection entry/exit interests, current Person and role/permission interests, subscribe-before-read behavior, fresh authority, preserved group-aware navigation and LiveView-owned invitation form/feedback state."
      },
      {
        "path": "docs/iterations/067-live-projection-queries/extraction-contract.md",
        "facts": "The frozen contract gives one query one public result assign, atomically replaces result and interests, subscribes before connected reads, clears failed results, and leaves form, flash, command and navigation policy with the LiveView owner."
      },
      {
        "path": "web/lib/memba_web/member_invitation_query.ex",
        "facts": "The accepted query has ID `:member_invitation`, assign `:invitation_context`, and stable inputs `club_id` and `authenticated_email`. Each load freshly resolves active-club authority, Person, active membership, member count and manage-members permission and returns `:forbidden` on access failure."
      },
      {
        "path": "web/test/memba_web/member_invitation_query_test.exs",
        "facts": "Accepted query proof covers coherent loading, attached-email identity, count entry/exit, fresh membership and permission loss, fail-closed inputs, all intended source-interest families and unrelated-club isolation."
      },
      {
        "path": "web/lib/memba_web/live/member_invitation_live/new.ex",
        "facts": "The current LiveView loads selected club, current member and active-member count directly from mount-captured identity clubs, has no committed-change handler, and stores form/validation, route, resend, delivery and flash state independently. Those transient responsibilities and existing markup/navigation must remain."
      },
      {
        "path": "web/test/memba_web/live/member_invitation_live/new_test.exs",
        "facts": "Existing focused tests lock host-selected club behavior, active-member count rendering, selected-group return links, the email-only form, initial authorization failures and signed-out return paths. They currently lack open-page refresh, isolation, transient-state and delivered access-loss proof."
      },
      {
        "path": "web/test/memba_web/live/member_invitation_live/send_test.exs",
        "facts": "Existing command proof locks normalized invitation delivery, the shared one-use profile-completion lifecycle, duplicate pending resend behavior and rejection of already-active members."
      },
      {
        "path": "web/lib/memba/membership.ex",
        "facts": "`invite_club_member/2` is explicitly actor-neutral; its documentation requires callers representing club Membership Admins to authorize the actor before invoking the shared lifecycle. A successful live-query result therefore must be freshly reconciled before this member-facing dispatch."
      },
      {
        "path": "packages/live_query/lib/live_query/binding.ex",
        "facts": "`Binding.bind/4` subscribes before the connected initial read and reconciles bind-window notifications; `rebind/3` refreshes stable inputs; `handle_notification/2` refreshes matching registrations only. Failed reads clear the public result and return query-ID/reason pairs for owner policy."
      },
      {
        "path": "web/lib/memba_web/live_query/memba_read_model_source.ex",
        "facts": "The accepted app adapter subscribes to committed `ReadModelChanges`, maps Membership, Person, Club and Role projector events to exact invalidations, and ignores unrelated projectors. The invitation LiveView should delegate notification classification to this source."
      },
      {
        "path": "web/lib/memba_web/live/member_group_live/new.ex",
        "facts": "This accepted nearby member form migration demonstrates binding a fresh-authorized context before rendering, preserving form-owned state across relevant refreshes, routing notifications through the generic binding and surfacing forbidden refreshes through existing private-surface behavior."
      },
      {
        "path": "docs/adr/0027-use-live-projection-queries-for-liveview-reads.md",
        "facts": "Accepted architecture requires one coherent query model with fresh authorized rereads while replacement of that query assign leaves form and navigation state alone; Memba-specific queries and notification mapping remain in the application."
      },
      {
        "path": "docs/reference/liveview.md",
        "facts": "Focused LiveView tests should exercise observable behavior through stable DOM IDs and supported helpers, avoid sleeps, preserve current navigation APIs, and keep forms as LiveView-owned `to_form/2` assigns."
      }
    ],
    "constraints": [
      "Keep one registered invitation query and one public `:invitation_context` result assign.",
      "Use `socket.assigns.current_identity_email` as the stable authorization identity; do not reuse `current_identity_clubs` as refresh authority.",
      "Initialize form and route state before binding so query replacements cannot reset transient state.",
      "Use `Binding.rebind/3` before the actor-neutral invitation dispatch and perform no invitation side effect when reauthorization fails.",
      "Preserve the binding-cleared socket when applying access-loss policy; do not retain or render stale private query data.",
      "Unexpected query, source or binding errors must raise or otherwise remain visible and must not be converted to ignored notifications or ordinary validation feedback.",
      "Relevant collection invalidation must update counts for members absent from the old result; do not depend only on represented member identities.",
      "Production changes should remain limited to `MembaWeb.MemberInvitationLive.New`, with focused changes in its existing test files, unless a concrete blocker is returned for replanning."
    ],
    "focused_validation": [
      "PATH=\"$PWD/bin:$PATH\" dev test test/memba_web/live/member_invitation_live/new_test.exs test/memba_web/live/member_invitation_live/send_test.exs test/memba_web/member_invitation_query_test.exs test/memba_web/live_query/memba_read_model_source_test.exs",
      "PATH=\"$PWD/bin:$PATH\" bin/mix format --check-formatted",
      "git diff --check"
    ],
    "completion_evidence_required": [
      "List every changed path and confirm production changes remain limited to the member invitation LiveView unless a blocker required replanning.",
      "Report each exact focused validation command, exit status and test count.",
      "Show that the connected page has one `:invitation_context` projection-backed result and no independent selected-club, current-member or active-member-count socket assigns.",
      "Show focused evidence that selected-club member entry and exit notifications update the already-open count while unrelated-club notifications leave the result and transient state untouched.",
      "Show focused evidence that relevant refreshes preserve typed email input and validation errors.",
      "Show focused evidence that delivered current-member membership or manage-members loss clears/leaves the private surface using fresh authority.",
      "Show focused evidence that submit performs fresh query reauthorization and does not create, resend or deliver an invitation after projected authority loss.",
      "Confirm existing group-aware return routes, initial authorization, email-only form, invite/resend, delivery feedback, active-member rejection, signed-out return and UI behavior remain green.",
      "Confirm no manual subscription, page-specific projector predicate, second query result, acceptance-feature change, package integration change or unscoped full-suite command was introduced.",
      "Confirm task 009E remains unchecked and no plan, todo, ADR, project documentation or delivery artifact was edited."
    ],
    "candidate_origins": [],
    "scenario_focus": null
  }
}