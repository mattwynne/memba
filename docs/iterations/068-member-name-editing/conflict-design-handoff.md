# 068 approved conflict design and implementation guidance

Status: approved by Matt, conditional on simple reusable implementation. The earlier external
DesignSync handoff and ADR proposal were superseded; Matt chose local HTML design in BB and
explicitly judged a new ADR unnecessary. No ADR acceptance or external handoff remains.

## Design paths

- [Name form](name-conflict-mockup.html): approved amber warning card/icon, neutral input, current
  conflicting value, Save anyway / Cancel my changes. Includes existing red validation comparison.
- [Multi-field exploration](multi-field-conflict-mockup.html): demonstrates the generic language and
  conflict list. Phone numbers are hypothetical, not added to 068.
- Base: `design-system/templates/account-settings.html` and root `styles.css` tokens/components.

Both local mock-ups render-verified in Chromium at 1320px/390px, no horizontal document overflow.
Static mock-ups do not prove connected behaviour, accessibility announcements or safe persistence.
No live DesignSync publication is claimed. Review evidence: [review-notes.md](review-notes.md) and
[final-ensemble-review.md](final-ensemble-review.md).

## Approved interaction and reusable default

Untouched forms follow current data. Dirty drafts stay visible. On a conflicting Save, an amber card
with a warning icon shows the newer value and explains that saving will replace it. Save anyway
explicitly confirms replacing that displayed value; Cancel my changes discards the draft, closes the
editor and displays latest authorized data without writing. No silent overwrite, automatic discard,
merge interface or proactive-warning machinery is required.

Use shared presentation and a small server-owned baseline/draft/latest/confirmation coordinator as
the default for forms editing existing saved data. Creation forms have no pre-existing value to
conflict with. 068 implements name editing only, not an app-wide migration. Preserve untouched
fields with changed-field patches, rather than submitting a stale whole-record replacement.

Draft edits invalidate confirmation. Query observations must not silently change the warning value
that the actor is confirming. Enter must not accidentally confer overwrite confirmation. Announce
new/repeated warnings, preserve input/error descriptions, manage focus when actions change, and
return focus to Edit on cancellation. Prove connected/browser transitions during implementation.

## Domain and application boundaries

- Field casting, normalization, comparison, coupled invariants, validation, authorization and atomic
  writes remain with the owning form/domain. No generic persistence registry or force-write API.
- Person rename preparation receives trusted server-established actor context separately from
  editable attrs, resolves the actor's Person and rejects another target before dispatch. Posted
  identities are not authority. Aggregate ID matching alone is not actor authorization. No-op and
  confirmation cannot bypass self-only authorization.
- Person compares normalized authoritative current values, not revisions. Jones → Green → Jones
  does not itself cause a conflict. An identical normalized target succeeds without an event.
  Confirmation warns again only if the current value conflicts with the displayed expectation.
- Conflict values must come from the authorized authoritative comparison result or synchronized
  authorized read. Success (including eventless no-op) and cancellation after conflict synchronize
  current readback using existing ADR 0022 checkpoint/barrier conventions. Do not discard a dirty
  draft or present stale data as confirmed current on bounded readback failure.
- Reuse the [spike](https://github.com/mattwynne/memba/blob/7b83d5b9f2189d6da6b1875967b21ba3f33df194/spikes/068-form-conflict/README.md)
  API/component pattern, not its fake writer or automatic cherry-pick. Flat comparable scalar values
  are the initial boundary; nested/multi-aggregate editing needs explicit modelling, not switches.

If implementation requires disproportionate infrastructure, return the trade-off to Matt rather
than silently weakening the approved policy. Keep staff refresh, photos and general form migration
out of scope. No workflow launch is authorized by this design artifact.
