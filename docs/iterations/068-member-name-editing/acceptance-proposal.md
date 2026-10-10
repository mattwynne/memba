# 068 acceptance formulation for Matt's review

Status: proposed wording for the approved example subjects; not yet executable feature changes.

Existing `member_profile.feature` photo scenarios remain unchanged. These three domain examples
replace the four old name examples. The fourth approved subject (untouched-form refresh) is covered
by the one browser journey below and focused LiveView tests: a domain adapter must not simulate tabs.

## Proposed domain examples — member_profile.feature

```gherkin
Rule: A Person's current name follows them across clubs and past contributions

    @iteration-068 @todo
    Scenario: Alice's corrected name appears across clubs and on earlier contributions
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is a member of Rockies Cycling Co-op
      And Alice is known as "Alice Smith"
      And Alice started the conversation "Trip planning night" in Kootenay Mountaineering Club
      And Alice replied to the conversation "Summer rides" in Rockies Cycling Co-op
      When Alice changes their name to "Alice Jones"
      Then Alice should be known as "Alice Jones" in Kootenay Mountaineering Club
      And Alice should be known as "Alice Jones" in Rockies Cycling Co-op
      And Alice's earlier conversation "Trip planning night" should show "Alice Jones" as its author
      And Alice's earlier reply to "Summer rides" should show "Alice Jones" as its author

Rule: A Person must have a valid name

    @iteration-068 @todo
    Scenario: Alice cannot replace their name with whitespace
      Given Alice is known as "Alice Smith"
      When Alice tries to change their name to "   "
      Then Alice should be told "Enter the name your clubs should see."
      And Alice should be known as "Alice Smith"

Rule: A conflicting stale change must not replace a newer name

    @iteration-068 @todo
    Scenario: Alice's older edit cannot undo a newer correction
      Given Alice began changing their name when it was "Alice Smith"
      And Alice has since changed their name to "Alice Jones"
      When Alice submits the older change to "Alice Brown"
      Then the change should be rejected because their name changed elsewhere
      And Alice should be known as "Alice Jones"
```

The club-qualified setup must not depend on ambiguous last-selected-club state. Step support is
implementation work; it is not changed during planning.

## Proposed browser journey — journeys/member_profile.feature

```gherkin
@journey @iteration-068
Feature: Correcting a name from Account settings

  Rule: A member can correct their name without leaving untouched forms behind

    @todo
    Scenario: Alice corrects their name while another Profile form is open
      Given Alice is signed in as a member of Kootenay Mountaineering Club
      And Alice is known as "Alice Smith"
      And Alice has an untouched name edit open in another Account settings tab
      When Alice opens Account settings from their member menu
      And Alice edits their Profile name to "Robin Jones" and saves it
      Then Alice should see "Robin Jones" in their Profile and member menu
      And Alice's member menu avatar should show the initials "RJ"
      And the untouched name form in the other tab should show "Robin Jones" without reloading
```

A different first name intentionally makes initials change observable. Alice remains the fixture's
Person identity after renaming. No extra journey is needed for every error case or member page.

## Focused tests rather than extra acceptance scenarios

- Empty and whitespace-only; normalization; 100/101 Unicode graphemes; punctuation/non-Latin and
  single-word names; invalid input leaves stored state unchanged.
- Dirty second form retains input and rejects stale Save even before notification. The approved
  warning shows the newer value with Save anyway / Cancel my changes. Explicit confirmation replaces
  only the shown value; a further intervening change requires renewed confirmation. Cancel my changes
  adopts current data without writing. Identical-target no-op and change-away-and-back semantics
  depend on approval of the proposed model.
- Current names on open dashboard/detail/delivery/shell surfaces, including historical authors
  no longer in an active-member list; no loss of unrelated form state; actor targeting and access.

## Review status

Matt approved the subjects and reuse-before-adding-journeys constraint. Repository inspection found
no existing Profile editing journey. Exact language, runner allocation and proposed model/UX are
awaiting review. No independent collaboration or ensemble review has been completed; this artifact
must not be represented as independently reviewed or ready for implementation.
