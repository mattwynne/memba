@wip
Feature: Member message deliverability
  Club members need confidence that important club messages are reaching other members.
  Memba shows simple receipt-style feedback to regular members.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, Carol, and Dana are people
    And Pat is a person
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club

  Rule: Any member can send a message to every active member of their club

    Scenario: Alice sends a club message
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
      And Alice should see the message was addressed to Alice, Bob, Carol, and Dana
      And Alice should not see Pat in the addressed members
      And Alice should see every addressed member's receipt status as "Sending"

  Rule: Members see simple receipt statuses for everyone addressed

    Scenario: Alice sees different receipt statuses for different members
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      And Carol's email for "Trip planning night" has been reported as bounced because "mailbox does not exist"
      And Dana has opened the email for "Trip planning night"
      When Alice views the message "Trip planning night"
      Then Alice should see Bob's receipt status for "Trip planning night" as "Delivered"
      And Alice should see Carol's receipt status for "Trip planning night" as "Delivery problem"
      And Alice should see Dana's receipt status for "Trip planning night" as "Opened"
      And Alice should see Alice's receipt status for "Trip planning night" as "Sending"

    Scenario: Bob sees the same shared receipt statuses
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      And Carol's email for "Trip planning night" has been reported as delayed because "recipient server is temporarily unavailable"
      When Bob views the message "Trip planning night"
      Then Bob should see Alice's receipt status for "Trip planning night" as "Sending"
      And Bob should see Bob's receipt status for "Trip planning night" as "Delivered"
      And Bob should see Carol's receipt status for "Trip planning night" as "Delivery problem"
