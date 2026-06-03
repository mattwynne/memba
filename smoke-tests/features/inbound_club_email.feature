Feature: Production inbound club email smoke tests
  These smoke tests send real email through public MX/provider wiring and then
  check the member-visible and mailbox-visible outcomes. They are intended for
  a controlled production smoke club named Smoke Test Club with slug test.

  Background:
    Given the production smoke configuration is valid
    And Memba staff can sign in
    And the smoke club exists
    And the smoke member can sign in

  Scenario: Unknown sender is rejected
    When an unknown sender emails the smoke club
    Then the unknown sender receives an unknown-sender rejection email
    And the smoke member should not see that club message

  Scenario: Known active member email is accepted and distributed
    When the smoke member emails the smoke club
    Then the smoke member sees that club message
    And the smoke member receives a distributed copy of that club message

  Scenario: Known active member email with an attachment is rejected
    When the smoke member emails the smoke club with an attachment
    Then the smoke member receives an attachment-not-supported rejection email
    And the smoke member should not see that club message
