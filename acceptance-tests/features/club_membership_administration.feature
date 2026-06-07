@iteration-027 @todo-domain @todo-ui
Feature: Club membership administration
  Clubs need trusted members who can manage membership without Memba staff doing every change.
  Memba grants each new club a default Membership Administrator role built from permission primitives.

# Rule: New clubs start with a Membership Administrator

    Scenario: A converted requester can administer membership for their new club
      Given Robin has requested Memba access for West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat converts Robin's West Coast Paddlers request
      Then Robin should be an active member of West Coast Paddlers
      And Robin should be a Membership Administrator of West Coast Paddlers

# Rule: Membership administration is authorized by permission

    Scenario: Robin grants membership administration to Alice
      Given Robin is a Membership Administrator of West Coast Paddlers
      And Alice is an ordinary member of West Coast Paddlers
      When Robin makes Alice a Membership Administrator of West Coast Paddlers
      Then Alice should be a Membership Administrator of West Coast Paddlers

    Scenario: Alice cannot grant membership administration to Bob
      Given Robin is a Membership Administrator of West Coast Paddlers
      And Alice is an ordinary member of West Coast Paddlers
      And Bob is an ordinary member of West Coast Paddlers
      When Alice tries to make Bob a Membership Administrator of West Coast Paddlers
      Then Bob should not be a Membership Administrator of West Coast Paddlers

# Rule: A club always has at least one Membership Administrator

    Scenario: Robin cannot remove the last Membership Administrator
      Given Robin is the only Membership Administrator of West Coast Paddlers
      When Robin tries to remove Robin as a Membership Administrator of West Coast Paddlers
      Then Robin should still be a Membership Administrator of West Coast Paddlers
