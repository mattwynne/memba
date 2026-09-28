@journey @iteration-066
Feature: Asking for Board membership from its page

  Scenario: Eve asks and Dan adds her from the request email
    Given KMC is a club
    And Alice and Dan are its club admins
    And Eve is its ordinary active club member
    And Alice is the only member of its group Board
    When Eve opens Board
    Then Eve should be offered Request access without a message composer
    And Eve should see neither Board conversations nor its membership list
    When Eve requests access to Board
    Then Eve should see "Your request has been sent."
    But Eve should still not belong to Board
    When Dan opens "Add Eve to Board" from the request email
    Then Dan should be offered the action to add Eve to Board
    But Eve should still not belong to Board
    When Dan confirms adding Eve to Board
    Then Eve should receive a welcome email with a link to Board
    When Eve opens Board from her welcome email
    Then Eve should have access to Board's conversations
    But Eve should still have no access to the Admin request conversation
