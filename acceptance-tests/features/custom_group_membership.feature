Feature: Managing custom group membership
  Group members and club admins manage custom-group membership.
  Joining a group is different from joining the club or becoming a club admin.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice and Dan are its club admins
    And Bob, Carol, and Eve are its ordinary active club members
    And Alice and Bob are the only members of its custom group Board

  @iteration-063 @not-domain
  Rule: The add-member picker is accessible by keyboard and input events

    Scenario: Bob searches and dismisses the picker
      When Bob opens Board's add-member picker
      Then the add-member search should have focus
      When Bob pastes "Carol" into the add-member search
      Then only Carol should be offered in the add-member picker
      When Bob presses Escape in the add-member picker
      Then the add-member picker should close and return focus to its trigger
      When Bob opens Board's add-member picker
      And Bob closes the add-member picker
      Then the add-member picker should close and return focus to its trigger

  @iteration-063 @todo-domain @todo-ui
  Rule: Group members and club admins may add active club members

    Scenario: Bob adds Carol without becoming a club admin
      When Bob adds Carol to Board
      Then Carol should belong to Board
      And Bob should remain an ordinary club member

    Scenario: Dan adds Carol without joining Board himself
      When Dan adds Carol to Board
      Then Carol should belong to Board
      But Dan should not belong to Board
      And Dan should still have no access to Board conversations

    Scenario: Dan adds himself before reading Board's discussions
      Given Board has the conversation "September agenda"
      When Dan adds himself to Board
      Then Dan should belong to Board
      And he should be able to read "September agenda"

    Scenario: Adding Carol again does not welcome her a second time
      Given Bob has added Carol to Board
      When Dan also adds Carol to Board
      Then Carol should have one active Board membership
      And Carol should have received one Board welcome email

  @iteration-063 @todo-domain @todo-ui
  Rule: Ordinary non-members cannot add themselves or anyone else

    Scenario Outline: Eve cannot change Board's membership
      When Eve directly tries to <change>
      Then Alice and Bob should remain Board's only members

      Examples:
        | change               |
        | add herself to Board |
        | add Carol to Board   |

  @iteration-063 @todo-domain @todo-ui
  Rule: Only existing active members of the same club may be added

    Scenario Outline: Bob cannot add someone who is not an active KMC member
      Given <membership>
      When Bob tries to add <person> to Board
      Then <person> should not belong to Board
      And <person> should not become an active KMC member through that attempt

      Examples:
        | person | membership                                      |
        | Pat    | Pat belongs to Nelson Paddling Club but not KMC   |
        | Robin  | Robin has been invited to KMC but has not joined  |
        | Carol  | Carol is no longer an active member of KMC        |

    Scenario: Board membership cannot grant Eve club-admin authority
      When Bob tries to add Eve to Admin as though it were a custom group
      Then Eve should not belong to Admin
      And Eve should remain an ordinary club member

  @iteration-064 @todo-domain @todo-ui
  Rule: Group members and club admins may remove group members

    Scenario: Bob removes Alice without removing her club authority
      When Bob removes Alice from Board
      Then Alice should no longer belong to Board
      And Alice should still be a club admin
      And Alice should still be able to manage Board's membership
      But Alice should no longer be able to read Board conversations

    Scenario: Dan removes Bob without joining Board himself
      When Dan removes Bob from Board
      Then Bob should no longer belong to Board
      And Bob should remain an active KMC member
      But Dan should not belong to Board

    Scenario: Eve cannot remove Bob while outside Board
      When Eve directly tries to remove Bob from Board
      Then Alice and Bob should remain Board's only members

  @iteration-064 @todo-domain @todo-ui
  Rule: Group removal never bypasses system-group membership protections

    Scenario: Bob cannot leave Everyone while remaining an active club member
      When Bob tries to leave Everyone as though it were a custom group
      Then Bob should remain in Everyone
      And Bob should remain an active club member

    Scenario: The last club admin cannot leave Admin using custom-group controls
      Given Alice is the only remaining club admin
      When Alice tries to leave Admin as though it were a custom group
      Then Alice should remain a club admin and a member of Admin
