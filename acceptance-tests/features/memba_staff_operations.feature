Feature: Memba staff operations
  Memba staff need a clear operations area that shows Memba's real data model
  so they can manage clubs and diagnose communication without pretending that people and memberships are the same thing.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice is a member of Kootenay Mountaineering Club
    And Alice is a member of Nelson Paddling Club
    And Pat is signed in as Memba staff

Rule: Staff navigation only offers working operations pages

    @not-domain
    Scenario: Pat opens the staff operations area
      When Pat opens the Memba staff area
      Then Pat should be able to navigate to Clubs
      And Pat should be able to navigate to People
      And Pat should be able to navigate to Messages
      And Pat should be able to navigate to Deliveries
      But Pat should not be offered unavailable staff pages such as Incoming or Roles

Rule: People are global records that can have memberships in multiple clubs

    Scenario: Alice belongs to two clubs
      When Memba staff review people
      Then Memba should list Alice as one person
      And Memba should show Alice's Kootenay Mountaineering Club membership
      And Memba should show Alice's Nelson Paddling Club membership

Rule: Staff review messages without composing them

    @not-domain
    Scenario: Pat opens diagnostics for an existing club message
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Pat opens the staff Messages page
      Then Pat should see "Trip planning night" for Kootenay Mountaineering Club
      When Pat opens the message diagnostics for "Trip planning night"
      Then Pat should see the staff delivery diagnostics for "Trip planning night"

    @not-domain
    Scenario: Pat cannot send a club message from the staff club page
      When Pat opens Kootenay Mountaineering Club in the staff area
      Then Pat should not be offered a way to send a club message as a member
