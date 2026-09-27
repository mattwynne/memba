Feature: Memba staff operations
  Memba staff need a clear operations area that shows Memba's real data model
  so they can manage clubs and diagnose communication without pretending that people and memberships are the same thing.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice is a member of Kootenay Mountaineering Club
    And Alice is a member of Nelson Paddling Club
    And Pat is signed in as Memba staff

Rule: People are global records that can have memberships in multiple clubs

    Scenario: Alice belongs to two clubs
      When Memba staff review people
      Then Memba should list Alice as one person
      And Memba should show Alice's Kootenay Mountaineering Club membership
      And Memba should show Alice's Nelson Paddling Club membership
