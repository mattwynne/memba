@iteration-062 @todo-ui
Feature: Creating custom club groups
  Club admins create private conversation spaces for active club members.
  A group has a name and a separately stored email slug: the part before @.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob and Eve are its ordinary active club members

  @todo-domain @todo-ui
  Rule: Only an active club admin can create a custom group and becomes its first member

    Scenario: Alice creates Board and belongs to it immediately
      When Alice creates the custom group "Board" in Kootenay Mountaineering Club
      Then Board should belong to Kootenay Mountaineering Club
      And Alice should be its only member
      And Dan should not belong to Board

    Scenario: Board membership does not let Bob create another group
      Given Bob belongs to the custom group Board
      When Bob tries to create the custom group "Trips" in Kootenay Mountaineering Club
      Then no custom group named "Trips" should be created

  @todo-domain @todo-ui
  Rule: Group names are unique within a club, ignoring case and surrounding spaces

    Scenario Outline: Alice cannot create another Board under a spelling variant
      Given Kootenay Mountaineering Club has a custom group named "Board"
      When Alice tries to create a custom group named <name> in Kootenay Mountaineering Club
      Then she should be told that the group name is already in use
      And no additional group should be created

      Examples:
        | name      |
        | "Board"   |
        | "bOaRd"   |
        | " Board " |

    Scenario: Board in another club does not reserve the name in KMC
      Given Nelson Paddling Club has a custom group named "Board"
      When Alice creates the custom group "Board" in Kootenay Mountaineering Club
      Then each club should have its own Board group

    Scenario Outline: A custom group cannot take a system group's name
      When Alice tries to create a custom group named "<name>" in Kootenay Mountaineering Club
      Then she should be told that the group name is already in use
      And the existing system group should be unchanged

      Examples:
        | name     |
        | Everyone |
        | admin    |

    Scenario: Alice and Dan both try to create Board
      When Alice and Dan concurrently try to create the custom group "Board"
      Then Kootenay Mountaineering Club should have exactly one Board group
      And only its successful creator should join through creation
      And the other admin should be told that the name is already in use

  @todo-domain @todo-ui
  Rule: A group's email slug is generated once and stored separately from its name

    Scenario: Board receives its own club-scoped email address
      When Alice creates the custom group "Board" in Kootenay Mountaineering Club
      Then Board should have the stored email slug "board"
      And Board's email address should be "board@kmc.clubs.memba.io"

    Scenario: A stored address identifies a group even when its name is different
      Given KMC has the custom group "Elected committee" with stored email slug "board"
      And Bob belongs to Elected committee
      When Bob emails "September agenda" to board@kmc.clubs.memba.io
      Then "September agenda" should be an Elected committee conversation
      And its stored email slug should still be "board"

  @todo-domain @todo-ui
  Rule: Email slugs are unique within a club and collisions receive a numeric suffix

    Scenario: Board gets board-2 because another group's stored slug is board
      Given KMC has the custom group "Elected committee" with stored email slug "board"
      When Alice creates the custom group "Board" in Kootenay Mountaineering Club
      Then Board's email address should be "board-2@kmc.clubs.memba.io"
      And Elected committee's address should remain "board@kmc.clubs.memba.io"

    Scenario: Another club's board address does not cause a suffix in KMC
      Given Nelson Paddling Club has a Board group with stored email slug "board"
      When Alice creates the custom group "Board" in Kootenay Mountaineering Club
      Then Board's email address should be "board@kmc.clubs.memba.io"

  @not-domain @todo-ui
  Rule: Group-name feedback and the proposed email address update while typing

    Scenario: Alice sees the email address before creating Trips
      When Alice enters "Trips" as a new group name
      Then she should see the proposed address "trips@kmc.clubs.memba.io"
      But Trips should not yet exist

    Scenario: Alice corrects a duplicate name without submitting
      Given KMC already has a group named "Board"
      When Alice enters " bOaRd " as a new group name
      Then she should be told immediately that the name is already in use
      When she changes the name to "Trips"
      Then the duplicate-name feedback should disappear
      And the proposed address should become "trips@kmc.clubs.memba.io"

    Scenario: Alice previews a numeric suffix and creates that group
      Given KMC has the custom group "Huts & maintenance" with stored email slug "huts-maintenance"
      When Alice enters "Huts maintenance" as a new group name
      Then the name should be accepted
      And the proposed address should be "huts-maintenance-2@kmc.clubs.memba.io"
      When Alice creates the group
      Then its stored address should match the proposed address

    Scenario: Clearing an edited name gives live blank-name feedback
      Given Alice has entered "Trips" as a new group name
      When Alice clears the name
      Then she should be told that the group needs a name
      And no proposed email address should be shown

  # Preview is advisory; creation authoritatively rechecks name and slug uniqueness.
  # Renaming and explicit slug editing remain deferred.
