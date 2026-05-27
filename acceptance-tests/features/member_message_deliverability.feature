Feature: Member message deliverability
  Club members need confidence that important club messages are reaching other members.
  Memba shows simple receipt-style feedback to regular members and detailed
  deliverability information to operators.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice, Bob, and Carol are people
    And Alice, Bob, and Carol are members of Kootenay Mountaineering Club

  Rule: Any member can send a message to the members of their club

    Scenario: A member sends a club message
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then the message should be addressed to Alice, Bob, and Carol
      And each addressed member should have a separate delivery record
      And each delivery should be sent through the email provider

  Rule: Members see simple receipt statuses

    Scenario: A sent message is waiting for delivery confirmation
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then Bob's receipt status for "Trip planning night" should be "sent"

    Scenario: A delivered message is shown as delivered
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as delivered
      Then Bob's receipt status for "Trip planning night" should be "delivered"

    Scenario: A delayed delivery is shown as a delivery problem
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as delayed because "recipient server is temporarily unavailable"
      Then Bob's receipt status for "Trip planning night" should be "delivery problem"

    Scenario: A bounced delivery is shown as a delivery problem
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as bounced because "mailbox does not exist"
      Then Bob's receipt status for "Trip planning night" should be "delivery problem"

    Scenario: A spam complaint is shown as a delivery problem
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as a spam complaint because "recipient marked the message as spam"
      Then Bob's receipt status for "Trip planning night" should be "delivery problem"

    Scenario: An opened message is shown as opened
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      When Bob opens the email for "Trip planning night"
      Then Bob's receipt status for "Trip planning night" should be "opened"

  Rule: Operators see detailed deliverability information per member

    Scenario: A delivered email is visible to operators
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as delivered
      Then Bob's operator deliverability status should be "delivered"

    Scenario: A delayed delivery is visible to operators
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as delayed because "recipient server is temporarily unavailable"
      Then Bob's operator deliverability status should be "delayed"
      And Bob's operator deliverability reason should be "recipient server is temporarily unavailable"

    Scenario: A bounced delivery is visible to operators
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as bounced because "mailbox does not exist"
      Then Bob's operator deliverability status should be "bounced"
      And Bob's operator deliverability reason should be "mailbox does not exist"

    Scenario: A spam complaint is visible to operators
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as a spam complaint because "recipient marked the message as spam"
      Then Bob's operator deliverability status should be "spam complaint"
      And Bob's operator deliverability reason should be "recipient marked the message as spam"

    Scenario: An opened email is visible to operators
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      When Bob opens the email for "Trip planning night"
      Then Bob's operator deliverability status should be "opened"
