# Members change their own name

Date: 2026-08-13
Status: draft — scope agreed; formulated examples and proposed model await Matt's review

## Goal

A signed-in club member can correct their own Person name in Account settings → Profile.
One name follows that Person across clubs, including names displayed on past contributions.

## Background / Context

067 is merged and in production. Its reusable live projection queries cover member-facing
ordinary-assign LiveViews, not staff views or streams. Reuse that foundation rather than creating
another refresh mechanism. The former validation of this plan predates 067 and does not establish
readiness.

Current repository evidence:

- `web/lib/memba/membership/person.ex` owns Person name and email-address state. It has no rename command.
- `web/lib/memba/membership/person_commands.ex` prepares commands; dispatch is separate. Do not
  resurrect the old plan's generic `Membership.rename_person/2` service shape by default.
- `web/lib/memba_web/member_settings_query.ex` returns fresh-authorized Person data and registers
  the exact Person interest; `MySettingsLive` already uses the live-query binding.
- `web/lib/memba_web/live_query/memba_read_model_source.ex` explicitly recognizes Person events.
  A new rename event must be added to that adapter, not just the projector.
- `MemberMessageDetail` and `Messaging.MessageQueries` resolve senders through current Person
  queries. Historical message events need not be rewritten to display the current name.
- `MemberDashboardPresentation` derives originator/participant names and initials from its name
  map. Delivery must verify coverage of historical authors who are no longer active members;
  an active-members-only name map is not sufficient proof of current historical names.
- The old draft incorrectly said the staff edit page already renames people. Its current save path
  replaces email addresses only. Do not introduce staff renaming in this iteration.

## Related Problems

- [Required onboarding details](../../problems/2026-06-08-club-onboarding-details-not-collected.md):
  adjacent but deliberately unresolved; no additional profile fields or onboarding policy.
- [Merge people](../../problems/2026-06-06-staff-merge-people.md): deliberately unresolved;
  changing a name does not merge identities, memberships, or history.

## Scope

### In scope — agreed by Matt

- Self-service editing of the signed-in Person's name from Account settings → Profile.
- One name across all clubs; current names on historical conversation roots and replies.
- Current names and derived initials on relevant open member pages and menus.
- Trim surrounding whitespace and collapse internal whitespace runs to single spaces.
- Reject blank/whitespace-only names and names longer than 100 characters after normalization.
  No restrictions on punctuation, scripts, accents, or single-word names.
- Update an untouched second name form when the latest name arrives.
- Preserve a conflicting unsaved edit. On conflicting Save, show the newer value and offer
  **Save anyway** or **Cancel my changes**. Explicit confirmation may replace only the newer value
  shown; if it changes again before confirmation, warn again. Never silently overwrite.
- Establish the generic conflict interaction as the default for forms editing existing saved data:
  shared warning-card presentation, wording and Save anyway / Cancel my changes actions, with
  reusable coordination for baseline/draft/latest values. Future editable forms should use this
  default rather than reimplement it. Field-specific validation, persistence and authorization stay
  with each form/domain. Creation-only forms have no existing saved value to conflict with.
- Do not migrate all existing forms in 068 or build a collaborative editor. Proactive warnings are
  not required.
- Matt approved the amber warning-card design with icon and **Save anyway / Cancel my changes**,
  conditional on keeping implementation simple. A small shared form-conflict abstraction is required,
  not a Profile-only implementation. If this requires substantial infrastructure or disproportionate
  complexity, stop and bring the trade-off back to Matt;
  do not silently substitute discard-on-conflict or last-write-wins.
- Smaller acceptance coverage: cross-club/history names, invalid-name rejection, untouched-form
  refresh, conflicting-save protection, plus one focused Profile editing browser journey.

### Out of scope

- Automatic refresh of already-open Memba staff views, including streams: Matt explicitly declined it.
  No staff migration or stream adapter is required.
- Photos (069); per-club names; other profile fields; renaming other people; club renaming.
- Notifications about name changes; audit/history UI; rate limits; merging people.
- Rewriting already-sent email bodies or historical message events.
- Workflow kaizen changes, healer experiments, and `experiment/unattended-delivery-skeleton`.

## Iteration Type

Behaviour-facing: club members can change their own name without administrative assistance.

## Acceptance Scenarios / Feature Files

BDD: **Required**. Matt approved the example subjects, not yet the exact proposed wording in
[acceptance-proposal.md](acceptance-proposal.md).

- `acceptance-tests/features/member_profile.feature`: consolidate the existing three rename success
  examples into one cross-club/history example; retain one invalid-name example; add one stale-save
  domain example. Preserve all 069 photo scenarios byte-for-byte.
- `acceptance-tests/features/journeys/member_profile.feature` (new): one Profile editing journey
  covers Save, menu/initials, and the untouched second connected form. The untouched-form example
  is UI behaviour, so prove it here and with LiveView tests, not by inventing a domain form model.
- There is no existing Profile editing journey. The iteration-053 “Alice opens Account settings
  from the member menu” example in `person_email_addresses.feature` is not a browser journey;
  preserve it unchanged.
- All new/changed scenarios retain `@iteration-068`. Future scenarios carry `@todo` until their
  intended runner supports them. Only the selected browser journey carries `@journey`.
- Individual page refreshes, Unicode/boundary validation and race permutations belong in focused
  tests, not duplicated browser scenarios.

Feature files have **not** yet been edited. This draft's acceptance proposal must be approved and
formulated into those exact files before publication as ready.

## Allowed acceptance feature changes

Implementation may remove `@todo` only from delivered 068 examples in the two files above and add
step support in their intended layers. Preserve iteration provenance and agreed outcomes. Do not
edit 069 scenarios or weaken existing settings coverage to make checks pass. Material changes to
rules/examples return to Matt, rather than being invented during delivery.

## Designs

Checked-in source: [Account settings](../../../design-system/templates/account-settings.html),
“Profile tab · name”: display, inline Edit/Save/Cancel, and field-error cards. Live DesignSync was
unavailable in this Pi session; no claim of live design sync or new render verification is made.

Retain the existing final name/photo design, implementing only the name half. Do not move the
existing avatar menu or build photo controls. Use a labelled input, associated inline error,
`aria-invalid`/`aria-describedby`, keyboard-operable controls, and narrow-screen wrapping without
requiring desktop controls to stack. Editing state is transient LiveView state, not a URL.

Existing error copy:

- Blank: “Enter the name your clubs should see.”
- Too long: “That name is too long.”

**Matt-approved conflict interaction:** retain the typed value and show:

> Changed elsewhere to “Alice Jones”.
> Saving your edit will replace that value.
>
> **Save anyway** · **Cancel my changes**

The field label remains “Your name”; the warning/actions are generic. **Save anyway** explicitly
confirms replacing the displayed newer value, not an unconditional force-write. If another change
wins before confirmation, show the new conflict and require confirmation again. **Cancel my changes**
discards the draft, closes the editor and displays the latest saved value without writing. Show this after a conflicting Save;
no proactive warning is required. This supersedes the earlier Cancel/re-edit-only proposal and the
rejected discard-with-toast alternative.

Matt explicitly directed design to continue here in BB with HTML mock-ups and the base design
language/components, superseding the proposed Claude Code/DesignSync handoff. Local proposal:
[name-conflict-mockup.html](name-conflict-mockup.html), with wide/narrow conflict layouts and action
outcomes, based on the checked-in Account settings design and root `styles.css` tokens. This is a
static design artifact, not application UI. Matt approved the amber card/icon treatment and
Save anyway / Cancel my changes wording, conditional on simple implementation. The
[multi-field exploration](multi-field-conflict-mockup.html) illustrates reuse only; phone numbers
and app-wide form changes remain out of scope. Required design review remains pending; no live
DesignSync publication or browser render verification is claimed. See
[conflict-design-handoff.md](conflict-design-handoff.md) for decision history.

After a successful matching refresh, the LiveView reconciles only its name form: untouched input
and its baseline follow the current name; dirty input and baseline stay intact. Other forms,
selected tab, reply drafts and navigation are preserved. Define untouched relative to the edit
baseline, so reverting input to that value permits automatic refresh again.

## Acceptance Criteria

- Edit pre-fills the current name; Cancel leaves persisted data unchanged and returns to display.
- Valid Save normalizes and persists the name, then shows current projected data.
- Invalid Save keeps input/error visible and does not change the saved name.
- A rename changes neither identity nor email addresses, verification, memberships, or roles.
- Member rows, root/reply authors, participant avatars, menu names and initials use current names,
  including on relevant already-open member pages and across clubs.
- Untouched second forms update; conflicting dirty forms do not silently overwrite a newer value,
  even when Save arrives before the other tab's live notification. Preserve the draft, show the
  newer value, and offer Save anyway / Cancel my changes. A repeated conflict requires renewed confirmation.
- Relevant open member refreshes retain fresh authorization and preserve unrelated transient state.
- No changes to staff-live freshness, sent email artifacts, or photos.

## Open Business Decisions

Core scope, validation, staff exclusion, concurrent-edit outcomes and example subjects are agreed.
Matt has approved generic conflict copy and explicit Save anyway / Cancel my changes recovery.
Matt approved the local visual treatment conditional on implementation simplicity. Exact formulated
Gherkin and the proposed domain model still await review.

## Domain Vocabulary

Reuse Person, Club, Club member, Message, Sender, and Memba staff from the canonical lexicon.
“Name” and “change their name” retain their ordinary meaning. No lexicon additions are proposed.
Command/event names, projections, edit baselines and live-query interests are solution-domain terms,
not new business concepts.

## Domain Model — proposed, not yet Matt-approved

- **Owner:** the existing Membership Person aggregate. No Profile aggregate or per-club identity.
- **Intent:** `RenamePerson`, containing Person identity, requested name, and the name that the
  edit started from (`expected_name`). The web boundary derives the target from the authenticated
  identity, never a submitted Person ID. Fresh settings authorization is checked before dispatch.
- **Invariant:** normalize and validate at the aggregate, not just in the browser. Proposed length
  measure is Elixir `String.length/1` (Unicode graphemes), not byte length.
- **Concurrency:** compare the submitted edit baseline with the aggregate's authoritative current
  name, not a projection. A different requested value with a stale baseline is rejected. This protects
  Save-before-notification and two simultaneous commands without requiring a name-version column.
  Explicit Save anyway submits a new attempt whose expected name is the newer value shown in
  the warning. A second intervening change rejects that attempt too; never bypass concurrency checks.
- **No-op:** if the normalized requested name already equals the aggregate's current name, succeed
  without an event, including two tabs submitting the same target. Name changes away and back to
  the baseline are not conflicts under value comparison; no newer differing name is overwritten.
  These small temporal clarifications require Matt's model agreement.
- **Fact:** `PersonRenamed` carries Person identity and normalized new name. Applying it changes
  only the aggregate's name; the Person projector changes only the corresponding read-model name.
- **Reads:** current Person names remain authoritative for displayed authors, not historical copies
  embedded in immutable sent artifacts. No historical event rewrite or messaging backfill is planned.
- **UI responsibility:** keep baseline, conflicting displayed value and dirty text outside the
  live-query result. Only explicit Save anyway confirms replacement of the displayed value;
  Cancel my changes adopts current data without writing. A query refresh must not silently make a stale
  draft saveable.
- **Preparation/dispatch:** extend focused Person command preparation and existing CommandDispatch;
  keep orchestration at the web boundary, consistent with current repository structure.
- **Shared form responsibility:** propose a small reusable conflict-state coordinator and warning
  component used by Profile now and defaulted for future existing-record edit forms. Keep app/UI
  conflict state distinct from field-specific aggregate concurrency enforcement. Generic UI reuse
  must not imply a universal last-write-wins/force-save command or trust client-supplied baselines.
- **Deferrals:** no general persistence/optimistic-locking framework, app-wide form migration, name
  history UI, collaborative editing, staff editing, notifications, or changes to unrelated Person
  creation/invitation rules.

## Architecture Decisions

Existing accepted ADRs remain authoritative:

- [0015: member LiveView](../../adr/0015-use-liveview-for-member-application-pages.md).
- [0021: committed read-model changes](../../adr/0021-publish-committed-read-model-changes.md).
- [0022: projection barriers](../../adr/0022-use-projection-barriers-for-read-your-writes.md).
- [0023: URL state](../../adr/0023-use-url-addressable-liveview-state.md).
- [0026: separate browser journeys](../../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md).
- [0027: live queries](../../adr/0027-use-live-projection-queries-for-liveview-reads.md).

ADR candidate: Matt has explicitly chosen the generic conflict interaction as the default for
existing-record edit forms across the app. Record this durable default and the shared UI/state
responsibility boundary after modelling/review; field-specific concurrency enforcement remains in
its owning domain. No app-wide form migration or general persistence framework is implied.
The Person-local expected-value check separately extends the existing aggregate boundary.
No new ADR has yet been drafted, reviewed or accepted.

## Implementation Plan — conditional on planning approval

1. Add focused Person rename preparation, command routing, aggregate validation/concurrency handling,
   event application and domain tests, preserving existing creation and email behaviour.
2. Project the new event; publish through existing post-commit ReadModelChanges. Extend the explicit
   Memba event adapter with exact Person invalidation; do not broaden to global refresh.
3. Verify current-name reads and represented-Person interests across member surfaces, including
   historical authors absent from the current active-member list. Correct any gaps without rewriting
   message history. See proof matrix below.
4. Add Profile inline states with server-owned actor/baseline, untouched-form reconciliation, dirty
   preservation, and the approved conflict treatment. Preserve existing email forms and tab state.
5. Add real-command/projector/PubSub LiveView integration proofs and the selected browser journey;
   implement domain examples and remove their temporary tags only when supported.
6. Run `dev check` on the exact staged/committed delivery state, inspect responsive presentation,
   and retain evidence. No delivery command is authorized by this planning document.

## Feasibility Spike

Matt explicitly authorized a small implementation spike in a separate thread/worktree:
@thread:thr_dagdffebpk. This is a planning exception for isolated experimental code, not approval
for production implementation or delivery. Test a minimal reusable conflict coordinator/presentation
with name-only and hypothetical two-field examples, explicit confirmation and repeat conflicts,
Cancel my changes, and preservation of untouched fields. Do not add phone support or migrate forms.

Spike completed and inspected; evidence is preserved on pushed branch
`bb/068-reusable-form-conflict-feasibility-spike-thr_dagdffebpk`, commit
`7b83d5b9f2189d6da6b1875967b21ba3f33df194`.

- [Report/API/limitations at the immutable spike commit](https://github.com/mattwynne/memba/blob/7b83d5b9f2189d6da6b1875967b21ba3f33df194/spikes/068-form-conflict/README.md).
- Paths on that commit: `spikes/068-form-conflict/draft.ex`, `warning.ex`, `draft_test.exs`,
  `warning_test.exs`, `fake_record.ex`, `form_harness.ex`, and `run.sh`.
- Finding: 62-line pure state coordinator plus 40-line stateless warning component; flat scalar
  forms do not require a LiveComponent, process, dependency, or persistence framework.
- Reusable operations: new/edit/observe/changes/attempt/rejected/cancel. Attempts describe changed
  fields plus expected values, never a whole-record replacement. Confirmation uses a frozen
  server-held warning snapshot; observing a newer projection does not silently change consent.
- Reuse the small API/component pattern and behavioural tests as evidence. Discard fake persistence
  and the render harness. Do not automatically cherry-pick the spike into delivery.
- Child reports 11 spike tests passing and `dev check` exit 0 on the exact pushed commit: 19 package
  tests, 1,811 app tests, 16 detector tests, six browser scenarios. Responsive screenshots were
  skipped by the detector. The full gate alone does not run spike tests; those were run separately.
- Proof boundary: no connected LiveView, real domain compare-and-write, real rename/projector/PubSub,
  browser conflict interaction or visual rendering is proved. Atomic comparison, authorization,
  validation and persistence remain mandatory domain responsibilities.
- Limits: comparable flat values only; casting/normalization, identical-target no-op and
  change-away/back semantics require model decisions. Nested/coupled fields and multi-aggregate
  edits are not solved. Server-owned state and fresh authorization remain essential.

Facilitator inspection confirms the prototype's small size and conditional-patch boundary, not
production correctness or model/ADR approval. The evidence supports Matt's simplicity condition for
flat scalar edit forms without extending 068 to app-wide form migration.

## Open Technical Decisions

- Matt approved explicit conflict confirmation/recovery. Approval of the proposed expected-name
  comparison, identical-target no-op and Unicode grapheme length remains part of model review.
- Matt approved the local BB HTML design and directed that the generic form-conflict pattern be
  the default for future editable forms, conditional on simple implementation. Required specialist
  review and render verification remain outstanding; the earlier external handoff is superseded.
- This durable default introduces an ADR candidate: shared editable-form conflict handling. Resolve
  the small abstraction's responsibility boundary through modelling and record Matt's decision in
  a reviewed ADR before ready publication. No ADR is accepted merely by this draft.
- The required domain-model review and final formulation review have not completed. No independent
  collaborators have participated in this thread; do not describe facilitator inspection as an
  ensemble or Three Amigos consensus.

## New Capability

A club member can correct the name everyone sees without administrative help, while a second tab
cannot silently undo a conflicting newer change.

## Validation Plan / Proof Boundaries

| Layer | Required proof | Does not prove |
| --- | --- | --- |
| Aggregate/preparation | normalization; empty/whitespace; 100/101 graphemes; non-Latin/punctuation/single-word names; stale and simultaneous writes; identical target; unrelated Person state unchanged; spoofed target rejected at web boundary | connected UI freshness |
| Projector/replay/adapter | old PersonCreated history plus rename replays; name-only projection; post-commit publication; exact Person event translation; unrelated identities ignored | every page displays the result |
| Member LiveView integration | real rename command → projector commit → PubSub → already-open settings/dashboard/conversation; current root/reply/participant names and initials, including inactive historical authors; unrelated query isolation | durable notification delivery |
| Other member surfaces | inspect/test group creation, compose, delivery detail and invitation query/shell name dependencies; preserve typed drafts and authorization on refresh | staff freshness |
| Form LiveView tests | untouched update; dirty preservation; stale Save before notification; explicit confirmed replacement; repeat conflict; Cancel my changes without write; Cancel/no-op; no silent baseline rebasing; validation; actor targeting | real browser DOM/focus behaviour |
| One browser journey | connected Profile editing, menu/initials and untouched second form; accessible controls; responsive checks per suite conventions | all validation/race permutations |
| Full regression | `dev check` on exact staged/committed state | product approval or launch permission |

Synthetic notifications alone are not end-to-end refresh evidence. Use the real command/projector
path for representative open-page proofs and barriers for negative assertions. Reuse 067's
subscribe-before-read, reconnect reconciliation and fresh-authorization guarantees. PubSub remains
non-durable: this iteration does not promise recovery of a lost broadcast to an uninterrupted page.

## Risks / Follow-ups

- Historical author name maps may be limited to active members; prove the intended display rather
  than assuming 067 already handles the new event or every author dependency.
- Preserve pending 069 scenarios and the final combined name/photo design.
- Do not impose new validation retrospectively on existing Person creation/history.
- A name can match another Person's name; this is not an identity merge or a new impersonation policy.

## Planning Completion and Launch Constraints

This remains **draft** until the proposed examples/UX/model are approved, required review is resolved,
features are updated and checked, the index is ready, and the exact planning commit is published.
Docs-only intermediate preservation requires `git diff --check`, not `dev check`. Acceptance edits
require `dev check`; no application/test plumbing may be changed during planning to make them pass.

The intended consumer is the new experimental workflow. Do not invoke old iteration-delivery,
`fabro deliver`, or validation/launch automatically. Parent @thread:thr_ra2ff7hjn2 owns eventual
integration and archival. Preserve this planning branch and leave the thread available while any
review or Matt decision remains outstanding.
