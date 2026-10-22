# Members cannot set their own profile photo

Captured: 2026-10-22

Status: Unresolved. Returned to the problem backlog at Matt's request; no implementation iteration is assigned.

## Problem

Members are represented by initials throughout Memba. They cannot choose a photo to help other club members recognise them in member lists and conversations.

The desired outcome is for a member to choose, replace or remove their own photo, with initials remaining the fallback when they have no photo. This is a problem to revisit, not an approved delivery plan.

## Decision to preserve

Matt has confirmed that profile photos are **public**: fetching a photo does not require signing in. This supersedes the signed-in-only serving rules in the earlier draft. It does not authorize adding photos to emails or other new surfaces.

## Earlier planning

This work was previously numbered 069, then 070, and marked needs-revision. On 2026-10-22 Matt asked to move it back into a problem rather than keep it in the iteration queue. The former 070 allocation is removed; it is not marked delivered or left as an ordered delivery dependency.

- [Previous iteration draft](profile-photos/previous-iteration-plan.md): retained as historical background, including design references and earlier technical choices. Its implementation checklist and validation claims are not current instructions. In particular, its signed-in-only statements contradict the later public-photo decision above.
- [Six draft examples](profile-photos/draft-examples.feature): moved out of the acceptance suite, with their rule, scenario and step wording preserved and the old iteration/TODO tags removed. They are discovery material, not executable acceptance coverage or an agreed future iteration.
- [Account settings design](../../design-system/templates/account-settings.html): earlier design coverage to review when this problem is selected again.

Before planning delivery, review the draft against the delivered [name editing](../iterations/068-member-name-editing/plan.md) and [Person merge](../iterations/069-console-person-merge/plan.md) behaviour, reconcile the obsolete serving rules, and revisit scope, modelling, upload validation and browser coverage. Moving this record does not make a new product or architectural decision.
