@iteration-027
Feature: Club membership administration
  Clubs need trusted members who can manage membership without Memba staff doing every change.
  Memba grants each new club a default Admin role built from permission primitives.

Rule: The first active member of a club becomes an Admin

    Scenario: A converted requester can administer membership for their new club
      Given Robin has requested Memba access for West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat converts Robin's West Coast Paddlers request
      Then Robin should be an active member of West Coast Paddlers
      And Robin should be an Admin of West Coast Paddlers

    @iteration-059 @todo-domain @todo-ui
    Scenario: Robin accepts the first invitation to an empty club
      Given West Coast Paddlers exists as a club with no active members
      And Pat has invited "robin@example.com" to join West Coast Paddlers
      When Robin accepts the invitation as "Robin Example"
      Then Robin should be an active member of West Coast Paddlers
      And Robin should be an Admin of West Coast Paddlers

    @iteration-059 @todo-domain @not-ui
    Scenario: Robin and Alice accept invitations at the same time
      Given West Coast Paddlers exists as a club with no active members
      And Pat has invited "robin@example.com" to join West Coast Paddlers
      And Pat has invited "alice@example.com" to join West Coast Paddlers
      When Robin and Alice accept their invitations at the same time
      Then Robin and Alice should be active members of West Coast Paddlers
      And exactly one of Robin and Alice should be an Admin of West Coast Paddlers
      And the other should be an ordinary member of West Coast Paddlers

Rule: Membership administration is authorized by permission

    Scenario: Robin grants membership administration to Alice
      Given Robin is an Admin of West Coast Paddlers
      And Alice is an ordinary member of West Coast Paddlers
      When Robin makes Alice an Admin of West Coast Paddlers
      Then Alice should be an Admin of West Coast Paddlers

    Scenario: Alice cannot grant membership administration to Bob
      Given Robin is an Admin of West Coast Paddlers
      And Alice is an ordinary member of West Coast Paddlers
      And Bob is an ordinary member of West Coast Paddlers
      When Alice tries to make Bob an Admin of West Coast Paddlers
      Then Bob should not be an Admin of West Coast Paddlers

Rule: A populated club always has at least one Admin

    Scenario: Robin cannot remove the last Admin
      Given Robin is the only Admin of West Coast Paddlers
      When Robin tries to remove Robin as an Admin of West Coast Paddlers
      Then Robin should still be an Admin of West Coast Paddlers

    @iteration-059 @todo-domain @todo-ui
    Scenario: Pat cannot remove Robin while Robin is the only Admin
      Given Robin is the only Admin of West Coast Paddlers
      And Alice is an ordinary member of West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat tries to remove Robin from West Coast Paddlers
      Then Pat should be told to make another member an Admin first
      And Robin should still be an active member of West Coast Paddlers
      And Robin should still be an Admin of West Coast Paddlers

    @iteration-059 @todo-domain @todo-ui
    Scenario: Pat removes Robin after Alice becomes an Admin
      Given Robin and Alice are Admins of West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat removes Robin from West Coast Paddlers
      Then Robin should no longer be an active member of West Coast Paddlers
      And Alice should still be an Admin of West Coast Paddlers

Rule: An established club cannot be emptied by member removal

    @iteration-059 @todo-domain @todo-ui
    Scenario: Pat cannot remove the club's only member
      Given Robin is the only active member of West Coast Paddlers
      And Robin is an Admin of West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat tries to remove Robin from West Coast Paddlers
      Then Pat should be told that an established club must retain an active member
      And Robin should still be an active member of West Coast Paddlers
      And Robin should still be an Admin of West Coast Paddlers
