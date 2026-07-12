Feature: Person email addresses
  People may be known by more than one email address while Memba still has one primary address for sending club mail.

Rule: A known alternate email address can identify a member

    Scenario: Alice signs in with her work email address
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      And Alice's alternate email address is "alice@work.example"
      When Alice signs in with "alice@work.example"
      Then Alice should be signed in
      And Alice should see Kootenay Mountaineering Club in their clubs

Rule: Club messages are sent to the primary email address only

    Scenario: Alice receives a club message at her primary email address
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      And Alice's alternate email address is "alice@work.example"
      When Bob sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then Alice should receive the email at "alice@example.com"
      And Alice should not receive the email at "alice@work.example"

Rule: Staff manage a person's known email addresses

    Scenario: Staff creates a person with primary and alternate email addresses
      Given Pat is signed in as Memba staff
      When Pat creates a person named Alice with primary email "alice@example.com" and alternate email "alice@work.example"
      Then Alice's primary email address should be "alice@example.com"
      And Alice's alternate email addresses should include "alice@work.example"

    Scenario: Staff changes a person's primary email address
      Given Pat is signed in as Memba staff
      And Alice has primary email "alice@example.com" and alternate email "alice@work.example"
      When Pat makes "alice@work.example" Alice's primary email address
      Then Alice's primary email address should be "alice@work.example"
      And Alice's alternate email addresses should include "alice@example.com"

Rule: Members manage their own email addresses from Account settings

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice opens Account settings from the member menu
      Given Alice is a member of Kootenay Mountaineering Club
      When Alice opens Account settings from their member menu
      Then Alice should see their name in Account settings
      And Alice should see Kootenay Mountaineering Club in their current clubs
      And Alice should see their primary email address

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice adds and verifies a new email address
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      When Alice adds "alice@work.example" to their Account settings
      Then Alice should see "alice@work.example" as pending verification
      And Alice should receive a verification email at "alice@work.example"
      When Alice verifies "alice@work.example" from that email
      Then Alice should see "Email verified, you can close this browser."
      And Alice should see "alice@work.example" as verified in Account settings

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice cannot make a pending email address primary
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      When Alice adds "alice@work.example" to their Account settings
      Then Alice should not be able to make "alice@work.example" primary

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice makes a verified alternate email address primary
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      And Alice has verified alternate email "alice@work.example"
      When Alice makes "alice@work.example" their primary email address
      Then Alice's primary email address should be "alice@work.example"
      And Alice's alternate email addresses should include "alice@example.com"

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice removes a non-primary email address but keeps one primary address
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      And Alice has verified alternate email "alice@work.example"
      Then Alice should not be able to remove "alice@example.com"
      When Alice removes "alice@work.example" from their Account settings
      Then Alice's alternate email addresses should not include "alice@work.example"
      And Alice's primary email address should be "alice@example.com"

    @iteration-053 @todo-domain @todo-ui
    Scenario: Alice resends verification for a pending email address
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has pending email address "alice@work.example"
      When Alice resends verification for "alice@work.example"
      Then Alice should receive a verification email at "alice@work.example"

    @iteration-053 @todo-domain @todo-ui
    Scenario: Removed pending email addresses cannot be verified later
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has pending email address "alice@work.example"
      When Alice removes "alice@work.example" from their Account settings
      And Alice opens the old verification link for "alice@work.example"
      Then Alice should see that the verification link is no longer valid
      And Alice's email addresses should not include "alice@work.example"

Rule: Pending email addresses do not identify a member until verified

    @iteration-053 @todo-domain @todo-ui
    Scenario: Signing in with a pending known address verifies it
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has pending email address "alice@work.example"
      When Alice signs in with "alice@work.example"
      Then Alice should be signed in
      And Alice should see "alice@work.example" as verified in Account settings

    @iteration-053 @todo-domain @todo-ui
    Scenario: Inbound email from a pending known address is rejected
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has pending email address "alice@work.example"
      When Alice emails Kootenay Mountaineering Club from "alice@work.example"
      Then Memba should reject the inbound email
      And Memba should not post the email as a club message from Alice
