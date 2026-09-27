@journey
Feature: Staff diagnose a club message without speaking as its members
  Staff can reach operating information across clubs without gaining a member's
  ability to send club messages.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice is a member of Kootenay Mountaineering Club
    And Alice is a member of Nelson Paddling Club
    And Pat is signed in as Memba staff

  Scenario: Pat follows a club message from staff navigation to diagnostics
    Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
    When Pat opens the Memba staff area
    Then Pat should be able to navigate to Clubs
    And Pat should be able to navigate to People
    And Pat should be able to navigate to Messages
    And Pat should be able to navigate to Deliveries
    When Pat opens the staff Messages page
    Then Pat should see "Trip planning night" for Kootenay Mountaineering Club
    When Pat opens the message diagnostics for "Trip planning night"
    Then Pat should see the staff delivery diagnostics for "Trip planning night"
    When Pat opens Kootenay Mountaineering Club in the staff area
    Then Pat should not be offered a way to send a club message as a member
