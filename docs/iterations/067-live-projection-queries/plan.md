# Live projection queries for open LiveViews

Date: 2026-09-28
Status: validated

## Goal

An open LiveView reflects relevant committed projection changes without each page separately maintaining a list of projector events and refresh handlers. Projection-backed page data is read through live queries: each query yields one coherent view model bound to one assign and owns its invalidation interests. Adopt the pattern across the club-member LiveViews that display projection-backed data through ordinary assigns. Staff stream-backed views are deliberately deferred.

## Background / Context

[ADR 0021](../../adr/0021-publish-committed-read-model-changes.md) established post-commit `Memba.ReadModelChanges` notifications. Today only seven of approximately twenty LiveViews subscribe, each with hand-written filtering and refresh code. Other pages can remain stale. Member dashboard and conversation pages already compose multiple projections and refresh on selected changes, but interest and read paths are maintained separately. Memba staff list/detail pages use Phoenix streams and are deliberately deferred. The problem is not a missing event publisher; it is the absence of a standard query-to-view-model subscription boundary. The public research found no maintained Commanded/LiveView package that turns arbitrary composed queries into an automatically refreshed assign; Commanded Ecto Projections provides the post-commit hook, while Phoenix LiveView provides process lifecycle and rendering diffs.

## Related Problems

- [Delivery status does not update live as webhooks come in](../../problems/2026-06-01-delivery-status-not-live.md): previously resolved for specific pages; this iteration generalizes the refresh pattern rather than re-solving delivery status.
- [New messages do not appear in the list automatically](../../problems/2026-06-04-new-messages-list-not-dynamically-updated.md): previously resolved for the member dashboard; preserve and migrate that behaviour.
- [CQRS/event-sourcing design drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): partially addresses the read-model/query boundary, not the note's command orchestration and side-effect concerns.

## Scope

### In scope

- A local path-dependency Mix application with an extractable generic live-query core, its own tests and documentation; no Hex publication now. Memba-specific projection notification mapping, authorization and query implementations stay in the app.
- A LiveView-owned live-query lifecycle: one registered query yields one view-model result bound to one assign; the LiveView process owns subscription and state, not a process per query.
- A query defines its read, the collection scopes and record identities whose committed changes could alter the result, and the means of recomputing those interests after a refresh. Memba translates post-commit projector notifications into matching invalidation keys. A newly entering or departing row must invalidate the collection even if its ID was absent from the previous result.
- On relevant committed changes, refresh only affected query results by re-reading projections; LiveView diffs rendered HTML. Do not patch view-model fields from source events or replay projectors. Recheck authorization when the query is refreshed; if access is lost, preserve the existing forbidden/not-found semantics rather than retaining private data.
- Move projection-backed reads in existing **club-member LiveViews using ordinary assigns** behind live queries. Inventory these member pages and document any exception. Do not migrate Memba staff, public, auth or stream-backed pages in this iteration. Keep commands, transient form state and navigation in the LiveView. A query only replaces its own assign.
- Use existing PubSub and projector `after_update/3` publishing; do not alter the event store or the underlying domain projections just to drive the UI.
- Subscribe before the connected initial read, account for notifications arriving while interests are installed, and reconcile on fresh mount/reconnect where supported by LiveView lifecycle. This does not guarantee recovery of a lost broadcast to an uninterrupted connected view.
- Integrate the local package with Mix, the production Docker build/release, and the project quality gate so package tests are actually exercised.

### Out of scope

- Name editing (renumbered iteration 068) and profile photos (069); neither PersonRenamed nor photo events are introduced here.
- Controllers, static pages, email rendering, and non-LiveView consumers; redesigning or merging underlying projection schemas; event-sourcing or Commanded replacement.
- One dedicated process per query, global shared result cache, generic SQL predicate introspection, patching individual fields from events, durable PubSub delivery, or publication to Hex.
- Automatically treating a transient input or command form as a projection-backed query result.
- Staff views (including their Phoenix streams), public club pages, auth/onboarding LiveViews and other non-member surfaces. Do not introduce a stream adapter or convert staff lists to ordinary assigns here.

## Iteration Type

Engineering-led behaviour change: existing open LiveViews gain automatic updates where their projection-backed data previously stayed stale. This is not a behaviour-neutral refactor. The single user-visible rule is that a connected page showing projected data reflects relevant committed changes without a manual reload.

## Acceptance Scenarios / Feature Files

BDD decision: Required for one stakeholder-readable example of the new live-update rule; do not expand the feature into an inventory of every page or a browser journey unless a browser-only failure is identified. One domain/application example in [`live_club_member_list.feature`](../../../acceptance-tests/features/live_club_member_list.feature): Bob has his club member list open; Alice becomes a member; Bob sees Alice appear automatically. A LiveView test can exercise the connected page and projection notification without a real browser. Focused LiveView tests cover other pages; package unit tests cover registration, scoped interests, query refresh and lifecycle. Existing message/delivery features remain unchanged.

## Allowed acceptance feature changes

- [`acceptance-tests/features/live_club_member_list.feature`](../../../acceptance-tests/features/live_club_member_list.feature): implementation may remove `@todo` from the one `@iteration-067` scenario and implement domain/application-level LiveView steps. Preserve its rule and example. No browser journey is planned.

## Designs

No new visual design is needed: an existing open page gains current data in its existing list/label components without a new action or visual state. Existing [club home design](../../../design-system/templates/club-home.html) supplies the Members surface. The plan does not change screen hierarchy or copy. Checked-in design sources were inspected; live DesignSync was unavailable in this session. Correct row/order/count updates and accessible DOM patches must preserve the existing page design. A lost-access transition must follow the existing forbidden/not-found treatment rather than expose private data.

## Acceptance Criteria

- Existing club-member LiveViews displaying projection-backed data through ordinary assigns no longer need independent event-filter lists to stay current; relevant committed updates refresh their affected view-model assign without reload, including list entry, removal, reordering and derived counts when applicable.
- Unrelated projection updates do not refresh unrelated queries or leak a different club's data.
- On a delivered relevant invalidation or reconciliation, a query refresh uses **fresh authorization inputs**, clears or leaves a private surface if access was revoked, and does not reuse a club list captured only at mount. An uninterrupted connected view cannot be guaranteed to notice a lost PubSub broadcast immediately.
- Editing and other transient UI state are not replaced by refreshing a query's assign.
- Existing delivery-status, group access and conversation refresh behaviour remains functional.
- Fresh mounts and reconnects read current projected state; bind-time race coverage is tested with subscribe-before-read and notification handling. PubSub is not durable and no connected-view guarantee is made after a lost broadcast.
- The local package's public API and tests have no dependency on Memba contexts or Commanded events; the app adapter contains those concerns. Production release includes the package and `dev check` executes its tests.

## Open Business Decisions

None known. This iteration does not add new membership, messaging, access or notification policy.

## Domain Vocabulary

Reuse Club, club member, Person, group and conversation as in [the canonical lexicon](../../problem-domain-terms.md). “Live query”, “projection”, “view model”, “assign”, “invalidation” and “subscription” are solution-domain terms and are not added to the problem-domain lexicon. No vocabulary change proposed.

## Technical Model

A view-specific query composes existing authorized read APIs, yielding one view model and a set of invalidation interests. Interests include collection scopes (to detect records entering/leaving a result) and identities of records actually represented. The binding layer holds the query, its current interests and one assign key inside the LiveView process, subscribes before the connected initial read, and refreshes only matching queries against committed projections. On each refresh it replaces the result and interests for that query; unrelated assigns and transient UI state remain untouched. A Memba adapter maps existing `ReadModelChanges` projector/event data to generic invalidation keys. A per-query migration matrix must list contributing projectors, event-to-interest mapping (including old and new scopes), fresh authorization sources and focused proof. When an event lacks precise scope, use a documented conservative invalidation rather than silently missing an update. Multiple contributing projectors can commit separately; each must invalidate the query so later commits converge. The generic package cannot infer SQL predicates or user permissions. Loading must check fresh authorization both initially and on refresh; query access errors are handed back for the existing private-surface transition. No streams are part of this contract in 067.

The package interface has three responsibilities: a query supplies a read callback returning either one view model plus interests or an access error; a source adapter subscribes the connected LiveView and converts a notification to invalidation keys; a binding installs the query under one assign, matches notifications against current interests, refreshes, and replaces the result plus interests. The adapter and query are passed in, never imported from Memba by the package. The LiveView owns navigation on an access error. The initial connected binding subscribes *before* reading, and a notification received across the first read/interest installation triggers conservative reconciliation. This is an interface contract, not a mandate for particular function names or a new OTP process.

For club home, start with **one authorized dashboard query** returning a coherent view model under one assign (`selected_group`, member rows/count, conversations and access-dependent data together), replacing today's map of independently assigned values. The member-list portion records interests for the selected club's membership collection and the represented people. Do not split dashboard queries unless measured need justifies coordinating multiple results across route and access transitions. A membership added/removed in that club invalidates the collection even if the person was absent from the old result; a relevant Person update invalidates represented names and initials. When a query also depends on groups/roles, those projectors must contribute invalidation keys, even when they commit at different times. For conversation detail, the query loads permitted messages and author names; a change that withdraws access causes a fresh authorization failure, not a retained private result. Mapping missing event scope falls back to broader invalidation, never silence.

Implementation checkpoints before freezing the package API: specify the package query/binding API and Memba adapter, prove it first against a member list and a composed conversation detail query, verify connected mount and reconnection against Phoenix LiveView's actual lifecycle, inventory the member LiveViews with query/exception mappings and focused tests, and verify packaging/test integration against Docker and `bin/dev`. No stream adapter is required. Do not claim that a PubSub broadcast is a durable read-model changelog.

## Architecture Decisions

Matt accepted [ADR 0027](../../adr/0027-use-live-projection-queries-for-liveview-reads.md), which extends ADR 0021 and sets the member LiveView live-query boundary.

## Implementation Plan

1. Inventory club-member LiveViews and projection-backed reads, existing refresh predicates, fresh authorization sources and access transitions; record queries to migrate, event/interest mappings, focused test evidence and justified exceptions. Exclude staff streams explicitly.
2. Design and prove the contract against the current club dashboard as one coherent query/view-model assign (member entry/exit and route/access transitions) and composed conversation detail (multiple projectors/access) before freezing the generic package API; define subscribe-before-read and bind-time reconciliation.
3. Implement and test the generic local Mix package's query binding, interests, invalidation, refresh and lifecycle contract without Memba or Commanded imports.
4. Implement the Memba adapter for committed projector notifications, scoped collection/identity invalidations and authorized view-specific queries composed from existing read APIs; use conservative invalidation when exact mapping is unavailable.
5. Migrate each in-scope member LiveView to query-result assigns, preserving its route, access, form state and UI. Ensure list entry/exit and existing live delivery/conversation flows do not regress.
6. Integrate the package with `web/mix.exs`, Docker release build and `dev check` so both package and web tests run in supported environments.
7. Add the focused acceptance example, focused tests per migrated member page and a real committed-projector-to-open-LiveView test, plus package unit tests for matching/mount/change/reconnect races; run `dev check`.

## Open Technical Decisions

Function names and the reconnect hook must be checked against the actual member LiveViews during implementation; the query/result/interest/source contract and the one-dashboard-view-model boundary are agreed. Streams are explicitly deferred. If a page cannot be adopted without changing a domain policy or its authorization semantics, stop and return that exception for decision rather than silently skipping it.

## New Capability

A reusable, locally packaged live-query layer lets a LiveView bind one authorized, composable projection-backed view model to one assign and keep it current on relevant committed changes, without hand-writing separate event handling for each page.

## Validation Plan

- Package unit tests: query binding and interest replacement, relevant/unrelated invalidations, rows entering/leaving collections, duplicate/out-of-order notifications, subscriber cleanup and relevant bind-time races.
- Focused LiveView tests: Bob's already-open club Members page gains Alice after admission without navigation; existing conversation and delivery detail refreshes still work; member lists/counts/order update; delivered revocation invalidations use fresh authority and remove private data; query refresh leaves unrelated form assigns unchanged; remount/reconnect reconciles. At least one test runs from a committed projector through PubSub to an open page, not solely a synthetic notification.
- Repository inventory/migration matrix: each in-scope club-member LiveView's projection-backed read either uses the live-query layer or has a documented exception, with scoped invalidations and focused regression evidence; package dependency graph cannot reference `Memba` or `Commanded`. Staff stream-backed pages are deferred.
- Build/release proof: path dependency compiled and included in production release; package tests are part of `dev check`.
- Final full `dev check` after implementation on the exact clean/staged state.

## Risks / Follow-ups

- Member LiveView migration risks inconsistent authorization, extra database queries and invalidation over-broadcast; the migration matrix, focused tests and query-count checks should catch these.
- A post-commit broadcast may be lost after a commit or while a process is unavailable; fresh reads/reconciliation mitigate but do not guarantee immediate durable delivery.
- Staff streams remain outside 067; any future migration must resolve coherent query-result/stream-count replacement separately. Do not equate minimal HTML diffs with minimal database work.
- Future name/photo iterations must express their query interests through this boundary rather than adding hand-written Person event handlers.
