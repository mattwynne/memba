@journey @iteration-066
Feature: Finding and joining a newly created Board
  Creating a private group does not make it readable to every club member.
  A club admin can admit someone without joining the group themselves.

  Scenario: Eve returns to Board after Dan admits her
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Bob and Eve are its ordinary active club members
    When Alice creates the custom group "Board" in Kootenay Mountaineering Club
    Then Alice should be its only member
    And Dan should not belong to Board
    When Eve selects the Board group
    Then Eve should see Board's name and be offered Request access
    But Eve should see neither Board conversations nor its membership list
    When Dan adds Eve to Board
    Then Eve should belong to Board
    But Dan should not belong to Board
    And Dan should still have no access to Board conversations
    When Eve selects the Board group
    Then Eve should see the Board group selected
    And Eve should see Alice in the member list
