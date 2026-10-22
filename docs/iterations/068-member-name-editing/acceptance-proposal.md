# 068 acceptance formulation record

Status: complete. Actual feature files are authoritative; this note records coverage allocation.

Matt approved four example subjects and one Profile editing journey, extending an existing journey
if present. Inspection found no existing Profile editing journey. Preserve the iteration-053
Account settings entry example and all profile-photo scenario behaviour unchanged
(later tagged iteration-070 after the separately approved renumbering). On 2026-10-22 Matt
returned photo work to the [problem backlog](../../problems/2026-10-22-members-cannot-set-profile-photos.md);
the six photo examples now live with that problem, outside the acceptance suite, with their
rule, scenario and step wording preserved. The allocation below records the delivered name work.

## Actual files

- [`member_profile.feature`](../../../acceptance-tests/features/member_profile.feature): three
  `@iteration-068 @todo` domain examples: cross-club/current historical names; whitespace-name
  rejection; stale edit rejection followed by explicit confirmation of the newer value.
- [`journeys/member_profile.feature`](../../../acceptance-tests/features/journeys/member_profile.feature):
  one `@journey @iteration-068 @todo` browser journey: Profile Save, current menu/name/initials and
  untouched second-form refresh. This UI subject is not simulated as a domain form entity.

The first domain example uses club-qualified conversation setup to avoid ambiguous fixture state.
The journey changes Alice Smith to Robin Jones so changed initials are observable while fixture
Person identity remains stable. No browser duplication of every validation/page/race permutation.

## Focused proof, not more stakeholder scenarios

Validation/Unicode boundaries, normalization, authorization, identical-target eventless success,
value-comparison semantics, dirty input preservation, explicit Save anyway, repeat conflicts and
Cancel my changes require focused tests. A focused browser interaction test covers actual DOM event
ordering, confirmation/cancel, announcements and focus beyond the selected journey. Delayed-projector
proof covers authoritative conflict values and synchronized no-op/cancel readback.

See [plan proof matrix](plan.md) for the authoritative obligations and exclusions. Pending `@todo`
examples are intentionally excluded from their runners until implementation, not delivery evidence.
The acceptance edit gate passed on exact state `12d98f759b24ed6334e14cb71027b9303a8e6730`.
Subsequent changes are planning prose only, not a new full-gate claim.

Bounded specialist and parent final two-family reviews are complete; policy/model decisions are
settled. [Final review synthesis](final-ensemble-review.md) retains panel, disagreement and limits.
Matt explicitly judged a new ADR unnecessary. No acceptance or ADR decision remains open.
