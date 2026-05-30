Feature: Operator email deliverability
  Operators need to understand which members are having email delivery problems
  so they can keep club communication reliable.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice and Bob are people
    And Alice and Bob are members of Kootenay Mountaineering Club
    And Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members

  Rule: Operators see detailed deliverability information per member

    @todo-web
    Scenario: A delivered email is visible to operators
      When Bob's email for "Trip planning night" is reported as delivered
      Then Bob's operator deliverability status should be "delivered"

    @todo-web
    Scenario: A delayed delivery is visible to operators
      When Bob's email for "Trip planning night" is reported as delayed because "recipient server is temporarily unavailable"
      Then Bob's operator deliverability status should be "delayed"
      And Bob's operator deliverability reason should be "recipient server is temporarily unavailable"

    @todo-web
    Scenario: A bounced delivery is visible to operators
      When Bob's email for "Trip planning night" is reported as bounced because "mailbox does not exist"
      Then Bob's operator deliverability status should be "bounced"
      And Bob's operator deliverability reason should be "mailbox does not exist"

    @todo-web
    Scenario: A spam complaint is visible to operators
      When Bob's email for "Trip planning night" is reported as a spam complaint because "recipient marked the message as spam"
      Then Bob's operator deliverability status should be "spam complaint"
      And Bob's operator deliverability reason should be "recipient marked the message as spam"

    @todo-web
    Scenario: An opened email is visible to operators
      Given Bob's email for "Trip planning night" has been reported as delivered
      When Bob opens the email for "Trip planning night"
      Then Bob's operator deliverability status should be "opened"
