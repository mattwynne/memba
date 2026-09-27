@journey
Feature: A member's club conversation crosses the website and email boundary
  Members can start and continue a club conversation on the website, see delivery
  feedback there, and find a new message sent to the club by email on the website.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, Carol, and Dana are people
    And Pat is a person
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club

  Scenario: Alice sends on the website, Bob replies there, and an inbound club email appears
    When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
    Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
    And Alice should see the message was addressed to Alice, Bob, Carol, and Dana
    And Alice should not see Pat in the addressed members
    And Alice should see every addressed member's status as "Sending"
    When Bob's email for "Trip planning night" is reported as delivered
    And Carol's email for "Trip planning night" is reported as bounced because "mailbox does not exist"
    And Bob views the message "Trip planning night"
    Then Bob should see Bob's status for "Trip planning night" as "Delivered"
    And Bob should see Carol's status for "Trip planning night" as "Delivery problem"
    Then Carol should not be following the conversation for "Trip planning night"
    When Carol follows the conversation for "Trip planning night"
    Then Carol should be following the conversation for "Trip planning night"
    When Bob replies "I can drive, three seats spare" to "Trip planning night"
    Then Alice should see Bob's reply in the conversation for "Trip planning night"
    When Carol stops following the conversation for "Trip planning night"
    Then Carol should not be following the conversation for "Trip planning night"
    When Alice emails "Gear swap shelf" to everyone@kmc.clubs.memba.io
    Then Alice should see the message "Gear swap shelf" in Kootenay Mountaineering Club
    And Alice should see the message was addressed to Alice, Bob, Carol, and Dana
    And Alice should not see Pat in the addressed members
