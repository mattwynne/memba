@wip
Feature: Person email addresses
  People may be known by more than one email address while Memba still has one primary address for sending club mail.

  Rule: A known alternate email address can identify a member

    Scenario: Alice signs in with her work email address
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice's primary email address is "alice@example.com"
      And Alice's alternate email address is "alice@work.example"
      When Alice requests a sign-in link for "alice@work.example"
      Then Alice should receive a sign-in link at "alice@work.example"
      When Alice follows the sign-in link
      Then Alice should be signed in
      And Alice should see Kootenay Mountaineering Club in their clubs

  Rule: Club messages are sent to the primary email address only

    Scenario: Alice receives a club message at her primary email address
      Given Alice is a member of Kootenay Mountaineering Club
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
