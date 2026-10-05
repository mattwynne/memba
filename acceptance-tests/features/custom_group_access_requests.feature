@iteration-066
Feature: Asking to be added to a group
  A member asks by sending a standard message to the club's Admin Group.
  Adding the member uses existing group membership rules.

  Background:
    Given KMC is a club
    And Alice and Dan are its club admins
    And Eve is its ordinary active club member
    And Alice belongs to its group Board

  Rule: Asking to join sends a standard message to the club admins

    Scenario: Eve asks to join Board
      When Eve requests access to Board
      Then a standard message identifying Eve and Board should be sent to the KMC Admin Group
      And Alice and Dan should be its email recipients
      And the message should link to adding Eve to Board
      But Eve should still not belong to Board

  Rule: The requester must still be an active member of the target club

    @todo
    Scenario Outline: Someone outside KMC cannot request Board membership
      Given <membership>
      When <person> tries to request access to Board
      Then no access-request message should be sent to the KMC Admin Group
      And <person> should gain no access to KMC groups

      Examples:
        | person | membership                                     |
        | Pat    | Pat belongs to Nelson Paddling Club but not KMC |
        | Eve    | Eve's KMC membership has ended                 |
