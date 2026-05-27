Feature: Member message deliverability
  Club members need confidence that important club messages are reaching other members.
  Memba shows simple receipt-style feedback to regular members.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, and Carol are people
    And Pat is a person
    And Alice, Bob, and Carol are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club

  Rule: Any member can send a message to the members of their club

    Scenario: A member sends a club message
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then the message should be addressed to Alice, Bob, and Carol
      And the message should not be addressed to Pat
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
