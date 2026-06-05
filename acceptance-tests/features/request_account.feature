@wip
Feature: Request account
  Memba protects its email reputation by keeping onboarding staff-approved.
  Interested club organisers can request access, but only Memba staff can turn a request into a club with an active first member.

  Rule: A public request does not grant access

    Scenario: Robin requests access without gaining immediate club access
      When Robin requests Memba access for West Coast Paddlers with a short note
      Then Robin should see that Memba will review the request
      And Memba staff should be notified about Robin's request
      And West Coast Paddlers should not exist as a club yet
      And Robin should not be able to sign in to West Coast Paddlers yet

  Rule: Signed-in people do not re-enter their known identity details

    Scenario: Alice requests a new club while signed in
      Given Alice is signed in
      When Alice opens the get-started page
      Then Alice should see their known name and email address as read-only request details
      When Alice requests Memba access for Nelson Trail Society with a short note
      Then Memba should record Alice's request with Alice's known name and email address

  Rule: Memba staff triage active requests

    Scenario: Pat converts a request into a club and first active member
      Given Robin has requested Memba access for West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat opens the active requests inbox
      Then Pat should see Robin's West Coast Paddlers request
      And Pat should see the suggested club slug "west-coast-paddlers"
      When Pat changes the club slug to "wcp" and converts the request
      Then West Coast Paddlers should exist with the slug "wcp"
      And Robin should be an active member of West Coast Paddlers
      And Robin's request should leave the active requests inbox

    Scenario: Pat converts a request from an existing person
      Given Alice is a person in Memba
      And Alice has requested Memba access for Nelson Trail Society
      And Pat is signed in as Memba staff
      When Pat converts Alice's Nelson Trail Society request
      Then Nelson Trail Society should exist as a club
      And Alice should be an active member of Nelson Trail Society
      And Memba should not create a duplicate person for Alice

    Scenario: Pat rejects a request without notifying the requester
      Given Robin has requested Memba access for Suspicious Sender Club
      And Pat is signed in as Memba staff
      When Pat rejects Robin's Suspicious Sender Club request with the internal note "Looks like spam"
      Then Robin's request should leave the active requests inbox
      And Robin should not receive an email about the rejected request
      And Suspicious Sender Club should not exist as a club
      And Robin should not be able to sign in to Suspicious Sender Club

  Rule: Converted requesters receive direct club access

    Scenario: Robin receives a welcome sign-in link for the new club
      Given Robin has requested Memba access for West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat converts Robin's West Coast Paddlers request
      Then Robin should receive a welcome email for West Coast Paddlers
      When Robin follows the welcome sign-in link
      Then Robin should be signed in to West Coast Paddlers
