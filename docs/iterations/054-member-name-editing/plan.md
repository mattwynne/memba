# Members change their own name

Date: 2026-08-13
Status: draft

## Goal

A signed-in member can change the name their clubs see, from the Profile tab of `/my/settings`.

After this iteration, a member who was added or invited under a wrong, partial, or outdated name
can fix it themselves, without asking a Membership Admin or Memba staff.

## Background / Context

Iteration 053 added `/my/settings` with three tabs — Profile, Clubs, Emails. Emails is fully
self-service; **Profile is display-only**. A Person's name is written once at creation
(`Membership.create_person/2`) or at invitation profile completion
(`Membership.complete_invited_club_member_profile/2`), and there is no command, event, or UI for
changing it afterwards. The name is what every club-facing surface shows: member rows, conversation
originators, reply authors, the avatar menu, and the initials drawn everywhere an avatar appears.

A member whose name is wrong today has no route to fix it. That is the whole of this slice.

Naming stays in existing domain language: this is a **Person** being renamed, not an "account
profile update". `Membership` already owns Person identity.

## Related Problems

- [`docs/problems/2026-06-08-club-onboarding-details-not-collected.md`](../../problems/2026-06-08-club-onboarding-details-not-collected.md):
  **depends on / partially adjacent, deliberately left unresolved.** That problem is about
  *collecting* required details (date of birth, emergency contact, club-specific fields) at
  onboarding. This iteration does not add any new profile field — it only makes the one field that
  already exists editable by its owner. The reusable required-details mechanism remains future work.
- [`docs/problems/2026-06-06-staff-merge-people.md`](../../problems/2026-06-06-staff-merge-people.md):
  **left unresolved.** Renaming is not merging. A member who exists twice still needs the staff merge
  workflow; this iteration must not become a workaround for it.

No captured problem note describes "members cannot change their own name" — it surfaced while
planning self-service profile editing, alongside iteration 055.

## Scope

### In scope

- A `Name` field on the Profile tab of `/my/settings` with a display row and an inline edit form
  (Edit → input + Save/Cancel), per the design.
- A Membership command/event pair for renaming a Person.
- Rejecting a blank or whitespace-only name with `Enter the name your clubs should see.`
- Trimming surrounding whitespace and collapsing the name to a single line before saving.
- A maximum name length of 100 characters, rejected with `That name is too long.`
- The new name showing everywhere the old one appeared: member rows, conversation originator and
  reply authors, the avatar menu, and derived initials.
- Live refresh of an open `/my/settings` via the existing `Memba.ReadModelChanges` topic, matching
  how the Emails tab already refreshes.

### Out of scope

- The profile **photo** — that is iteration 055. The Profile tab's photo field is designed and
  will be built there; this iteration leaves the existing initials avatar untouched.
- Per-club display names. One Person has one name across every club they belong to.
- Any other profile field (pronouns, phone, date of birth, emergency contact, club-specific fields).
- Staff or Membership Admin renaming another Person from the admin area — the existing staff edit
  path is not changed.
- Renaming a **club**. Unrelated aggregate.
- Notifying clubs, admins, or fellow members that someone changed their name.
- Rewriting names captured inside already-sent email bodies.
- Name-change history, audit display, or rate limiting.

## Iteration Type

Behaviour-facing.

The changed user-observable rule: **a member owns the name their clubs see, and can change it.**
Previously only Memba staff (via the admin people edit page) or the one-time invitation
profile-completion form could set it.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

This changes who can do what (a member may now rename themselves), it is visible to members and to
everyone in their clubs, and it carries a validation rule and a cross-club consequence worth an
explicit example. Three "default to Gherkin" signals apply.

New feature file
[`acceptance-tests/features/member_profile.feature`](../../../acceptance-tests/features/member_profile.feature),
shared with iteration 055. This iteration's scenarios are tagged `@iteration-054 @todo-domain @todo-ui`:

Rule: A member can change their own name

- Alice corrects the name her clubs see.
- Alice's new name replaces her old one everywhere her club sees her (member list + a conversation
  she started).
- Alice's new name follows her to every club she belongs to.

Rule: A member must have a name

- Alice cannot leave her name blank.

Both project Cucumber runners exclude these while tagged: the browser profile is
`not @not-ui and not @todo-ui` (`acceptance-tests/cucumber.js`) and the domain profile is
`not @not-domain and not @todo-domain` (`web/config/test.exs`), so the planning scenarios do not turn
the build red before implementation.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_profile.feature`: implementation may remove or narrow the
  temporary `@todo-domain` / `@todo-ui` tags on the four `@iteration-054` scenarios as domain and
  browser step support is delivered, and add the step definitions those scenarios need. Reason: the
  scenarios are written ahead of implementation as the acceptance criteria for this slice. The
  `@iteration-054` tags must be preserved. Implementation must not weaken, rename, or delete a
  scenario to make it pass; the `@iteration-055` scenarios in the same file belong to the next
  iteration and must be left alone.

## Designs

The Profile tab's name field is designed and pushed:
[`design-system/templates/account-settings.html`](../../../design-system/templates/account-settings.html)
→ cloud `templates/account-settings/account-settings.html`. Render-verified headlessly at 1320px
(no console/network errors, no horizontal overflow) before pushing.

The template covers the **final** state of the Profile tab across both iterations 054 and 055.
This iteration builds only the name half; the photo field ships in 055.

Relevant surfaces, from the template's "Profile tab · name" row:

- **Name — display:** a `Name` field label above a row containing the current name and an `Edit`
  button (`.profile-field[data-field="name"][data-state="display"]`).
- **Name — editing:** the row is replaced in place by an inline form — a labelled `Your name` text
  input plus `Save` and `Primary`/ghost `Cancel` buttons grouped in `.profile-name-form__actions`.
  There is no modal.
- **Name — empty-name error:** the input takes `.input-error`, `aria-invalid="true"` and
  `aria-describedby`, with the message `Enter the name your clubs should see.` rendered as a
  `.field-error` beneath the form. Note this is an **inline field error**, not the `.alert` treatment
  the Emails tab uses for its address-level errors.

New page-local classes the template introduces for this field: `.profile-fields`, `.profile-field`,
`.profile-field__label`, `.profile-name-row`, `.profile-name-form`, `.profile-name-form__actions`,
`.input-error`, `.field-error`. These are page-local to the settings screen, not shell vocabulary —
they belong in the settings LiveView's styles, not in `styles.css`, unless a second screen needs them.

**Implementation-architecture note (not a design decision):** per
[ADR 0015](../../adr/0015-use-liveview-for-member-application-pages.md) the field's display/editing
swap is LiveView state, not client-side JS. Unlike the Profile/Clubs/Emails tab selection, "am I
editing my name right now" is transient interaction state, **not** URL-addressable state under
[ADR 0023](../../adr/0023-use-url-addressable-liveview-state.md) — it needs no route of its own.

## Acceptance Criteria

- The Profile tab of `/my/settings` shows the member's current name with an `Edit` action.
- Choosing `Edit` replaces the display row with an inline form pre-filled with the current name.
- `Cancel` restores the display row with the name unchanged.
- `Save` with a changed, valid name updates the name and returns to the display row.
- Saving a blank or whitespace-only name is rejected with `Enter the name your clubs should see.`,
  the form stays open, and the stored name is unchanged.
- Saving a name longer than 100 characters is rejected with `That name is too long.`
- Surrounding whitespace is trimmed and internal runs of whitespace collapse to single spaces before
  the name is stored.
- After a rename, the member's club member rows show the new name.
- After a rename, conversations the member started and replies they sent show the new name as author.
- After a rename, the avatar menu and every derived initials avatar reflect the new name.
- A member belonging to more than one club sees the new name in all of them.
- Renaming does not alter any other Person state: email addresses, verification state, primary
  address, memberships, and roles are untouched.
- An open `/my/settings` in another browser updates when the name changes.
- Existing person, membership, and messaging behaviours continue to pass.

## Open Business Decisions

None known.

Decided during planning:

- **One name per Person, not per club.** A member is one person across Memba; a per-club display name
  would need a new per-membership concept and is explicitly out of scope.
- **No notification.** Renaming yourself is not an event other members are told about.
- **Already-sent emails keep the old name.** A delivered email is a sent artefact and is not rewritten.

## Implementation Plan

1. Inspect the current Person aggregate, `create_person` / `complete_invited_club_member_profile`
   flows, the Person projection, and `MembaWeb.MySettingsLive` before changing anything.
2. Add a `RenamePerson` command and `PersonRenamed` event in `Memba.Membership`, following the
   existing command/event conventions (see `add_person_email_address.ex` /
   `person_email_address_added.ex` for the current shape).
3. Enforce the name rules in the Person aggregate: non-blank after trimming, at most 100 characters,
   whitespace normalised. Renaming to the identical name is a no-op that emits no event.
4. Add `Membership.rename_person/2` as the application-service entry point, returning a tagged error
   the LiveView can render rather than raising.
5. Handle `PersonRenamed` in the Person projector so the read model carries the new name, and publish
   the change on the existing `Memba.ReadModelChanges` topic per
   [ADR 0021](../../adr/0021-publish-committed-read-model-changes.md).
6. Confirm the club-facing read models that display names (member rows, conversation originators,
   reply authors) resolve through the Person read model rather than denormalised copies. If any hold
   a copied name, update that projector too — this is the main unknown and step 1 should settle it.
7. Add the name display/edit states to the Profile tab of `MySettingsLive`, following
   `design-system/templates/account-settings.html`, with stable IDs for LiveView tests.
8. Subscribe/extend the existing settings LiveView read-model subscription so a rename refreshes an
   open page.
9. Add domain tests for the aggregate rules and the projector.
10. Add LiveView tests for display → edit → save, cancel, blank rejection, over-length rejection, and
    live refresh.
11. Implement the `@iteration-054` acceptance scenarios and remove their `@todo-domain @todo-ui` tags.
12. Run `dev check` and fix all issues.

## Open Technical Decisions

- **Whether any read model stores a denormalised copy of a Person's name.** Step 6 exists to settle
  this. If conversation/message projections copied the author name at write time, this iteration must
  decide between backfilling those projections on rename or resolving names at read time. Resolving
  at read time is preferred — it keeps one source of truth for a name — but the choice depends on what
  step 1 finds, and it may change the size of the slice. Flag it during implementation rather than
  guessing now.

## New Capability

Members own their own identity in Memba: the name their clubs see is theirs to correct, without
staff or admin involvement. The domain gains an explicit `PersonRenamed` fact, which later work
(merging duplicate people, audit trails, name-change history) can build on.

## Validation Plan

- Run `dev check` after implementation.
- Domain/context tests:
  - renaming a Person emits `PersonRenamed` and updates the read model;
  - a blank or whitespace-only name is rejected;
  - a name over 100 characters is rejected;
  - whitespace is trimmed and normalised;
  - renaming to the same name emits no event;
  - email addresses, memberships, and roles are unaffected by a rename.
- LiveView tests:
  - the Profile tab renders the current name and an Edit action;
  - Edit opens a pre-filled inline form;
  - Cancel leaves the name unchanged;
  - Save updates the name and closes the form;
  - blank input renders `Enter the name your clubs should see.` and keeps the form open;
  - an open settings page refreshes after a rename elsewhere.
- Acceptance tests:
  - the four `@iteration-054` scenarios in `member_profile.feature`, with the temporary
    `@todo-domain @todo-ui` tags removed.
- Manual demo:
  1. Sign in as an existing club member with a wrong name.
  2. Open the avatar menu → Account settings → Profile.
  3. Edit the name, save, confirm the display row and the avatar-menu initials update.
  4. Open the club member list and confirm the new name on the member row.
  5. Open a conversation that member started and confirm the author name.
  6. Try to save a blank name and confirm the inline error.

## Risks / Follow-ups

- If any messaging projection copied the author's name at write time, renaming will look inconsistent
  until that projection is addressed — see Open Technical Decisions. This is the most likely source
  of surprise in this slice.
- Members can now rename themselves to anything, including another member's name. Impersonation
  within a club is a trust question this iteration does not address; capture a problem note if it
  turns out to matter.
- Renaming is not merging duplicate people
  ([`2026-06-06-staff-merge-people.md`](../../problems/2026-06-06-staff-merge-people.md)) and should
  not be treated as a substitute for it.
- The Profile tab remains half-editable until iteration 055 adds the photo field.
