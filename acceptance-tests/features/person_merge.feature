Feature: Merge duplicate people
  Memba staff can consolidate an uncomplicated duplicate without losing verified contact addresses or historical attribution.

Rule: Verified addresses follow the surviving person

    @iteration-070
    Scenario: Staff merges a duplicate person's verified address
      Given Alice has the primary email "alice@example.com"
      And Alicia has the primary email "alice@work.example"
      When Memba staff merge Alicia into Alice
      Then "alice@example.com" should identify Alice
      And "alice@work.example" should identify Alice
      And Alice's primary email address should be "alice@example.com"
      And Alicia should no longer be an active person account

Rule: Duplicate club access is collapsed without changing the survivor

    @iteration-070
    Scenario: Both people already belong to the same club
      Given Alice is a member of Kootenay Mountaineering Club
      And Alicia is an ordinary member of Kootenay Mountaineering Club
      When Memba staff merge Alicia into Alice
      Then Alice should still be an active member of Kootenay Mountaineering Club
      And Alicia should no longer be an active member of Kootenay Mountaineering Club

Rule: A merge never silently loses a club membership

    @iteration-070
    Scenario: Only the duplicate belongs to a club
      Given Alice has the primary email "alice@example.com"
      And Alicia has the primary email "alice@work.example"
      And Alicia is a member of Kootenay Mountaineering Club
      When Memba staff try to merge Alicia into Alice
      Then the person merge should be rejected because a membership needs reconciliation
      And "alice@work.example" should still identify Alicia
      And Alicia should still be an active member of Kootenay Mountaineering Club
