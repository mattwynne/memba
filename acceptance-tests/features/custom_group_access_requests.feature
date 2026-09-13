@iteration-065 @todo-domain @todo-ui
Feature: Asking club admins for custom-group access
  A request is an ordinary message to Admin, not a tracked application.
  Admins grant membership through ordinary group membership management.

  Background:
    Given Kootenay Mountaineering Club has club email slug "kmc"
    And Alice and Dan are its club admins
    And Eve is its ordinary active club member
    And Alice belongs to its custom group Board
    And Eve belongs to neither Board nor Admin

  Rule: Request access sends a standard message to Admin in one action

    Scenario: Eve asks for Board access without composing a message
      When Eve requests access to Board
      Then a standard access-request message should be sent to the KMC Admin group
      And the message should identify Eve and Board and link to Board's membership management
      And Alice and Dan should receive the request through Admin's normal email delivery
      And Eve should be shown confirmation that her request was sent
      And Eve should not be asked to compose or edit a message

  Rule: Requesting grants access to neither the target group nor the Admin conversation

    Scenario: Eve cannot read the admins' discussion of her request
      Given Eve has requested access to Board
      When Alice replies "I will add Eve" in the Admin request conversation
      Then Eve should not be able to read the request conversation or its replies
      And Eve should not follow that conversation or receive Alice's reply by email
      And Eve should still not belong to Board

    Scenario: Dan adds Eve through ordinary membership management
      Given Eve has requested access to Board
      When Dan adds Eve to Board
      Then Eve should belong to Board
      And Eve should receive a welcome email with a link to Board
      But Eve should still have no access to the Admin request conversation

  Rule: Repeated requests are ordinary messages rather than a pending-request workflow

    Scenario: Eve asks again before anyone adds her
      Given Eve has already sent a request for Board access
      When Eve requests access to Board again
      Then another standard message identifying Eve and Board should be sent to Admin
      And Eve should be shown confirmation that this request was sent
      But Eve should still not belong to Board

  Rule: Requests must come from an active member of the target club

    Scenario: Pat cannot request access across clubs
      Given Pat belongs to Nelson Paddling Club but not KMC
      When Pat directly tries to request access to KMC's Board
      Then no access-request message should be sent to KMC Admin
      And Pat should gain no access to KMC groups

    Scenario: Eve cannot send a request after her club membership ends
      Given Eve's KMC membership has ended
      When Eve directly tries to request access to Board
      Then no access-request message should be sent to KMC Admin
      And Eve should gain no access to Board

  # Internal/communication failures use existing generic app error handling.
  # No bespoke technical-failure scenarios, editable composer, pending records,
  # approve/deny actions, or deliberate-request duplicate suppression.
