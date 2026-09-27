@iteration-062
Feature: Creating custom club groups
  Club admins create private conversation spaces for active club members.
  A group has a name and a separately stored email slug: the part before @.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob and Eve are its ordinary active club members

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
