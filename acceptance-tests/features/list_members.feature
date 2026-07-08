@iteration-049
Feature: List club members
  Club members need to see who belongs to their club and what roles people hold.

  Rule: Active members show their assigned roles

    Scenario: A member sees assigned roles in the member list
      Given Alice, Bob, and Carol are active members of Kootenay Mountaineering Club
      And Bob has the roles Treasurer and Secretary in Kootenay Mountaineering Club
      And Carol has the role Trip organizer in Kootenay Mountaineering Club
      When Alice views the member list for Kootenay Mountaineering Club
      Then Bob's member row should show the roles Secretary and Treasurer
      And Carol's member row should show the role Trip organizer
      And Alice's member row should show no roles

  Rule: Removed members are not listed

    Scenario: A removed member had a role
      Given Alice, Bob, and Carol are active members of Kootenay Mountaineering Club
      And Bob has the role Treasurer in Kootenay Mountaineering Club
      And Bob is removed from Kootenay Mountaineering Club
      When Alice views the member list for Kootenay Mountaineering Club
      Then Bob should not appear in the member list
      And Alice and Carol should appear in the member list
