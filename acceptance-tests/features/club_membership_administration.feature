@iteration-027
Feature: Club membership administration
  Clubs need trusted members who can manage membership without Memba staff doing every change.
  Memba grants each new club a default Admin role built from permission primitives.

Rule: New clubs start with an Admin

    Scenario: A converted requester can administer membership for their new club
      Given Robin has requested Memba access for West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat converts Robin's West Coast Paddlers request
      Then Robin should be an active member of West Coast Paddlers
      And Robin should be an Admin of West Coast Paddlers

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

Rule: A club always has at least one Admin

    Scenario: Robin cannot remove the last Admin
      Given Robin is the only Admin of West Coast Paddlers
      When Robin tries to remove Robin as an Admin of West Coast Paddlers
      Then Robin should still be an Admin of West Coast Paddlers
