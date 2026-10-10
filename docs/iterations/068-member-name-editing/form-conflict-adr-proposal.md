# Default to shared conflict handling for existing-record edit forms

Date: 2026-10-01

## Status

Proposed record of Matt's agreed direction; explicit acceptance of this record pending.
Kept in the iteration folder until reviewed/accepted; it is not an accepted repository ADR.

## Context

068 enables changing a Person's name. A second open form may contain untouched data or a conflicting
unsaved edit. Silent last-write-wins loses newer data; automatically discarding the draft loses the
actor's work. Matt chose an amber warning with the latest value and explicit Save anyway / Cancel
my changes, and directed that this be the generic default for forms, not a Profile-only solution.
Implementation must remain simple. The isolated spike at
`7b83d5b9f2189d6da6b1875967b21ba3f33df194` demonstrates a small pure coordinator and stateless
warning component for flat scalar fields; it does not prove authoritative persistence correctness.

## Decision

Establish shared conflict-state coordination and warning presentation as the default for forms
editing existing saved data. Start with flat scalar Person-name editing in 068; creation forms have
no pre-existing value to conflict with. Do not migrate all existing forms in this iteration.

- Keep draft, edit baseline, latest observations and the shown conflict snapshot server-owned.
- An untouched form follows latest data. A dirty form retains its draft and edit baseline.
- Ordinary Save submits changed fields and their expected values. Never replace a whole record
  merely because the browser posted a whole form.
- The owning domain/application boundary authorizes, validates and atomically checks expectations
  against authoritative state before writing. For Person rename, the Membership preparation entry
  point receives trusted server-established actor context separately from editable attrs, resolves
  the actor's Person, and rejects another target before preparing/dispatching a command. Posted
  actor/Person IDs are not trusted. Raw CommandDispatch is an internal trusted boundary, not an
  alternative public self-service API; aggregate ID matching alone is not actor authorization.
  Authorization runs for ordinary Save, confirmation and identical-target no-op. Retain fresh
  settings authorization; do not introduce a general authorization framework.
- A projection/UI comparison alone cannot enforce conditional write safety. Conflict warning values
  come from an authorized authoritative comparison result or synchronized authorized read. Successful
  readback, including eventless identical-target success, and cancellation after conflict must use
  existing ADR 0022 checkpoint/barrier conventions to obtain current authorized projection data.
  The no-op may depend on an earlier rename whose projector/notification has not caught up. A bounded
  readback failure retains the dirty draft and uses existing feedback handling rather than discarding
  work or confirming stale data. No new synchronization framework or guarantee about writes after
  the checkpoint is introduced.
- A rejected conflict shows authoritative latest values in an amber warning card with an icon,
  preserves the draft, and offers Save anyway / Cancel my changes.
- Save anyway confirms replacement of the values shown, not an unconditional force-save. If the
  authoritative current value conflicts with that expectation under the domain comparison policy,
  require a new warning/confirmation. Person uses normalized value equality, not revisions:
  Jones → Green → Jones does not itself invalidate confirmation, and an identical normalized target
  succeeds without an event. New draft edits invalidate confirmation.
- Cancel my changes discards the draft, closes the editor and shows current authorized saved data
  without writing. Confirmation never bypasses validation or authorization.
- Shared coordination/presentation stays in the web layer. Casting, normalization, field-specific
  comparison policy, coupled-field invariants and persistence remain with the owning form/domain.
  Nested and multi-aggregate forms need explicit modelling, not speculative framework switches.

Use the spike API/component pattern as reference, not an automatic cherry-pick. Avoid a generic
persistence registry, force-write API, automatic retry or collaborative merge engine. If production
reuse needs disproportionate complexity, stop and return the trade-off to Matt rather than silently
weakening the conflict behaviour. Future editable fields should reuse this default and its tests.

## Alternatives

- Profile-only conflict code: smaller initially but repeats policy/state/presentation for each form;
  Matt explicitly chose a reusable default instead.
- Last write wins: silently replaces newer data; rejected by Matt.
- Automatically cancel a conflicting edit/toast: loses draft work; rejected in favour of choice.
- General merge or revision framework: more machinery than this simple scalar slice currently needs.

## Consequences

Easier: consistent user choices, preserved drafts, shared accessible warning presentation and less
per-form reinvention. An amber warning distinguishes conflict from invalid field data. Changed-field
patches avoid overwriting fields the actor did not edit.

Harder: every adopting domain must supply safe conditional writes and authorized current values;
shared UI cannot manufacture that safety. Normalization/comparison semantics need domain tests.
Connected input preservation, event ordering, repeated conflicts and accessibility require integration
proof. Deterministic delayed-projector tests must cover authoritative conflict values, eventless
identical-target success, cancellation readback and draft preservation on bounded readback failure.
Direct unauthorized application-entry attempts must fail, including eventless and confirmation paths. Existing forms do not acquire the behaviour merely by accepting this record. Initial reuse is
bounded to comparable flat scalar fields, not arbitrary document/collection merging.

No accepted ADR is superseded. ADR 0027 still governs member query refresh and transient-state
ownership; staff streams stay excluded. This decision does not authorize implementation launch.
