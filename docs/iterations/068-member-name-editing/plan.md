# Members change their own name

Date: 2026-08-13
Status: merged

## Delivery boundary

The `merged` status becomes authoritative when this candidate is published on main; on a private
branch it is release intent, not a claim of publication. Publication requires independent source
acceptance, exact committed `dev check` and connected browser proofs, and safe integration with
public main. The parent owns publication, normal CI/Fly observation and deployed verification.
The status alone does not establish or claim production verification.

The approved scope, designs, model decisions and planning evidence below are retained as history.
Statements about then-current repository gaps or pending implementation describe the planning
baseline, not the completed candidate. The three 068 domain examples and Profile editing browser
journey are now executable; all six deferred 070 photo scenarios retain their behaviour. The historical
unattended attempt is not resumed or relabelled as delivered.

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
- Photos (070); per-club names; other profile fields; renaming other people; club renaming.
- Notifications about name changes; audit/history UI; rate limits; merging people.
- Rewriting already-sent email bodies or historical message events.
- Workflow kaizen changes, healer experiments, and `experiment/unattended-delivery-skeleton`.

## Iteration Type

Behaviour-facing: club members can change their own name without administrative assistance.

## Acceptance Scenarios / Feature Files

BDD: **Required**. Matt approved the four example subjects and reuse-before-adding-journeys rule.
The actual feature files below are authoritative; [acceptance-proposal.md](acceptance-proposal.md)
records formulation history, not a competing specification.

- `acceptance-tests/features/member_profile.feature`: consolidate the existing three rename success
  examples into one cross-club/history example; retain one invalid-name example; add one stale-save
  domain example. Preserve all 070 photo scenarios byte-for-byte except the separately approved iteration-tag renumbering.
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

Feature files are now formulated in those exact paths, with future scenarios tagged `@todo` in
 their intended runners. Three domain examples and one browser journey express the four agreed
subjects; the stale example includes explicit confirmation. Exact language review remains part of
planning completion. All 070 photo examples retain their behaviour; their iteration tags were subsequently renumbered.

## Allowed acceptance feature changes

Implementation may remove `@todo` only from delivered 068 examples in the two files above and add
step support in their intended layers. Preserve iteration provenance and agreed outcomes. Do not
edit 070 scenario behaviour or weaken existing settings coverage to make checks pass. Material changes to
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
and app-wide form changes remain out of scope. Bounded specialist and final two-family reviews
are complete. Both mock-ups were render-verified in Chromium at 1320px and 390px with no horizontal
overflow; this is static-layout evidence, not production interaction proof. No live DesignSync
publication is claimed. See
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

None known in behavioural scope. Matt approved generic conflict copy/actions, local visual
 treatment, reusable default and bounded simplicity. In the parent conversation he explicitly chose
current normalized value comparison rather than revisions: Jones → Green → Jones does not itself
cause a conflict. A target equal to the current normalized name succeeds without PersonRenamed.
Do not re-open this edge case or add revision tracking. Final whole-plan review is complete and
its scope-preserving corrections are incorporated. Matt explicitly judged a new ADR unnecessary;
no ADR acceptance checkpoint remains.

## Domain Vocabulary

Reuse Person, Club, Club member, Message, Sender, and Memba staff from the canonical lexicon.
“Name” and “change their name” retain their ordinary meaning. No lexicon additions are proposed.
Command/event names, projections, edit baselines and live-query interests are solution-domain terms,
not new business concepts.

## Domain Model

- **Owner:** the existing Membership Person aggregate. No Profile aggregate or per-club identity.
- **Intent:** `RenamePerson`, containing Person identity, requested name, and the name that the
  edit started from (`expected_name`). The web boundary derives the target from the authenticated
  identity, never a submitted Person ID. Fresh settings authorization is checked before dispatch.
- **Trusted actor/self-only contract:** the Membership rename application/preparation entry point
  receives a server-established actor context separately from editable attrs, resolves the actor's
  Person identity, and rejects a target other than that Person before preparing/dispatching any
  command. The web adapter passes authenticated context, not posted actor/Person IDs. Raw command
  dispatch is an internal trusted boundary, not an alternative public self-service entry point.
  Aggregate target-ID matching is consistency validation, not actor authorization. Self-only
  authorization must run for Save, Save anyway and identical-target no-op; use current preparation
  and CommandDispatch conventions, not a new general authorization framework.
- **Invariant:** normalize and validate at the aggregate, not just in the browser. Use Elixir
  `String.length/1` (Unicode graphemes), not bytes or browser UTF-16 maxlength, after normalization.
  Keep raw input for the form while comparing normalized requested/current values; do not mutate
  existing historical names or retroactively apply new validation to creation/history.
- **Concurrency — Matt-approved:** compare normalized expected/current name values at the Person
  aggregate, not a projection. A different requested value with a currently differing baseline is
  rejected. This protects Save-before-notification and simultaneous commands without a revision.
  Explicit Save anyway is a new conditional attempt against the normalized value shown in the
  server-held warning. Reject again if current value differs at execution. A change away and back
  to that same value is not a conflict; do not claim detection of every intervening rename.
- **No-op:** if the normalized requested name already equals the aggregate's current name, succeed
  without an event, including two tabs submitting the same target. Name changes away and back to
  the baseline are not conflicts under value comparison; no newer differing name is overwritten.
  Matt explicitly approved these semantics in the parent conversation. Authorization runs before
  no-op success too; the spike fake writer is not the production policy.
- **Fact:** `PersonRenamed` carries Person identity and normalized new name. Applying it changes
  only the aggregate's name; the Person projector changes only the corresponding read-model name.
- **Reads:** current Person names remain authoritative for displayed authors, not historical copies
  embedded in immutable sent artifacts. No historical event rewrite or messaging backfill is planned.
- **Readback/lag:** conflict results must supply authorized authoritative current values from the
  comparison outcome, or use an authorized read synchronized to that committed state. Do not put a
  stale ordinary projection value in the warning. After success, including eventless identical-target
  success, synchronize readback using existing ADR 0022 checkpoint/projector barriers and reread
  authorized Person/settings data before presenting a confirmed current display. A no-op emits no
  new notification, but the earlier winning rename may still be pending in the Person projector.
  Cancellation after conflict also obtains current authorized data with the existing synchronization
  convention before discarding the draft/closing the editor. Bounded readback failure retains the
  draft and existing feedback handling; never claim stale data is confirmed current or discard work
  while unable to obtain the latest value. This is bounded read-your-writes coordination, not a new
  synchronization framework or guaranteed observation of writes committed after the checkpoint.
- **UI responsibility:** keep baseline, conflicting displayed value and dirty text outside the
  live-query result. Only explicit Save anyway confirms replacement of the displayed value;
  Cancel my changes adopts current data without writing. A query refresh must not silently make a stale
  draft saveable.
- **Preparation/dispatch:** extend focused Person command preparation and existing CommandDispatch;
  keep orchestration at the web boundary, consistent with current repository structure.
- **Shared form responsibility:** use a small reusable conflict-state coordinator and warning
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

**No new ADR required.** Matt explicitly decided “No that does not merit an ADR.” This removes the
record/acceptance requirement, not the agreed behaviour or review corrections. The shared simple
form-conflict default, web/domain responsibility boundaries, trusted actor/self-only preparation,
conditional saves and synchronized readback are implementation guidance in this plan and
[design notes](conflict-design-handoff.md). No numbered ADR or ADR-index change is created.

## Implementation Plan

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

- No open concurrency-mechanism choice: Matt approved normalized current-value comparison,
  identical-target no-op and no revision tracking. Shared UI stays small per the reviewed spike.
- Matt approved the local BB HTML design and generic form-conflict default, conditional on simple
  implementation. Static render verification and bounded specialist review are complete; the
  external handoff is superseded.
- Bounded specialist findings are retained in [review-notes.md](review-notes.md). Parent's final
  whole-plan review is complete with two independent completed families (GPT-6 Astra and Gemini
  3.1 Pro Preview); Claude did not finish and no verdict was counted. Preserve actual panel,
  disagreement and limits in [final-ensemble-review.md](final-ensemble-review.md).
- Both scope-preserving final findings are incorporated in the model and proof matrix:
  explicit trusted actor/self-only preparation responsibility and synchronized readback, including
  delayed-projector conflict/no-op/cancel cases. No second ensemble round or new framework.
- None known. Matt explicitly judged an ADR unnecessary; no record acceptance remains.

## New Capability

A club member can correct the name everyone sees without administrative help, while a second tab
cannot silently undo a conflicting newer change.

## Validation Plan / Proof Boundaries

| Layer | Required proof | Does not prove |
| --- | --- | --- |
| Aggregate/preparation | normalization; empty/whitespace; 100/101 graphemes; non-Latin/punctuation/single-word names; stale and simultaneous writes; identical target; unrelated Person state unchanged; spoofed actor/target rejected at web boundary; direct unauthorized rename entry-point attempt rejected before preparation/dispatch, including no-op and confirmation | connected UI freshness |
| Projector/replay/adapter | old PersonCreated history plus rename replays; name-only projection; post-commit publication; exact Person event translation; unrelated identities ignored | every page displays the result |
| Readback with deterministic delayed Person projector | conflict displays authoritative winning value while projection lags; eventless identical-target success synchronizes with earlier winning commit; Cancel after conflict obtains current authorized data before dropping draft; bounded readback timeout preserves draft and never confirms stale data | observing writes committed after the synchronization checkpoint |
| Member LiveView integration | real rename command → projector commit → PubSub → already-open settings/dashboard/conversation; current root/reply/participant names and initials, including inactive historical authors; unrelated query isolation | durable notification delivery |
| Other member surfaces | inspect/test group creation, compose, delivery detail and invitation query/shell name dependencies; preserve typed drafts and authorization on refresh | staff freshness |
| Form LiveView tests | untouched update; dirty preservation; stale Save before notification; explicit confirmed replacement; repeat conflict; Cancel my changes without write; Cancel/no-op; no silent baseline rebasing; validation; actor targeting | real browser DOM/focus behaviour |
| One browser journey plus focused browser interaction test | journey: connected Profile editing, menu/initials and untouched second form; focused interaction test: retained dirty input, warning announcement, explicit confirmation/cancellation and repeated warning focus; responsive checks per suite conventions | all validation/race permutations |
| Full regression | `dev check` on exact staged/committed state | product approval or launch permission |

Synthetic notifications alone are not end-to-end refresh evidence. Use the real command/projector
path for representative open-page proofs and barriers for negative assertions. Reuse 067's
subscribe-before-read, reconnect reconciliation and fresh-authorization guarantees. PubSub remains
non-durable: this iteration does not promise recovery of a lost broadcast to an uninterrupted page.

## Risks / Follow-ups

- Historical author name maps may be limited to active members; prove the intended display rather
  than assuming 067 already handles the new event or every author dependency.
- Preserve pending 070 scenario behaviour and the final combined name/photo design.
- Do not impose new validation retrospectively on existing Person creation/history.
- A name can match another Person's name; this is not an identity merge or a new impersonation policy.

## Planning Completion and Launch Constraints (historical)

Scope, examples, local designs and current-value/no-op direction are agreed. Required bounded
review and parent final two-family review are complete; corrections are incorporated. Matt judged
an ADR unnecessary. The ready plan, index, features and design/review evidence are published together.
`dev check` passed on exact clean committed state `12d98f759b24ed6334e14cb71027b9303a8e6730`;
subsequent changes only clarify planning prose/status, so `git diff --check` applies and no new full
gate is required. Do not attribute that earlier full gate to a later untested commit. Implementation
must run its own exact-state `dev check`; pending `@todo` features are not proof of delivered behaviour.

The intended consumer is the new experimental workflow. Do not invoke old iteration-delivery,
`fabro deliver`, or validation/launch automatically. Parent @thread:thr_ra2ff7hjn2 owns eventual
integration and archival. Preserve this planning branch and leave the thread available while any
review or Matt decision remains outstanding.
