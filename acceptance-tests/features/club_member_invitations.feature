@iteration-028
Feature: Club member invitations
  People with membership-management authority invite people to join a club by email instead of creating active members directly.
  An invitation only becomes an active membership after the invitee follows the link and completes any required profile details.

Rule: Staff invite new members by email

    Scenario: Robin accepts an invitation and completes their profile
      Given Pat is signed in as Memba staff
      And West Coast Paddlers exists as a club
      When Pat invites "robin@example.com" to join West Coast Paddlers
      Then "robin@example.com" should receive an invitation to join West Coast Paddlers
      And Robin should not be an active member of West Coast Paddlers yet
      When Robin follows the invitation link
      Then Robin should be asked for their name
      When Robin enters "Robin Example" as their name
      Then Robin should be an active member of West Coast Paddlers
      And Robin should be signed in to West Coast Paddlers

    Scenario: Alice accepts an invitation as an existing person
      Given Alice is a person in Memba
      And Alice is not a member of West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat invites Alice to join West Coast Paddlers
      Then Alice should receive an invitation to join West Coast Paddlers
      When Alice follows the invitation link
      Then Alice should be an active member of West Coast Paddlers
      And Alice should be signed in to West Coast Paddlers

Rule: Membership Admins invite new members by email

    @iteration-029
    Scenario: Robin invites Dana to join West Coast Paddlers
      Given Robin is a Membership Admin of West Coast Paddlers
      When Robin invites "dana@example.com" to join West Coast Paddlers
      Then "dana@example.com" should receive an invitation to join West Coast Paddlers
      And Dana should not be an active member of West Coast Paddlers yet
      When Dana follows the invitation link
      Then Dana should be asked for their name
      When Dana enters "Dana Example" as their name
      Then Dana should be an active member of West Coast Paddlers
      And Dana should be an ordinary member of West Coast Paddlers
      And Dana should be signed in to West Coast Paddlers

Rule: Membership invitations are authorized by club permission

    @iteration-029
    Scenario: Alice cannot invite someone to join West Coast Paddlers
      Given Alice is an ordinary member of West Coast Paddlers
      When Alice tries to invite "dana@example.com" to join West Coast Paddlers
      Then Alice should be told she cannot invite members to West Coast Paddlers
      And "dana@example.com" should not receive an invitation to join West Coast Paddlers

Rule: Invited people complete required profile details before membership starts

    Scenario: Robin leaves before entering their name
      Given Pat has invited "robin@example.com" to join West Coast Paddlers
      When Robin follows the invitation link
      Then Robin should be asked for their name
      And Robin should not be an active member of West Coast Paddlers yet
      When Robin leaves without entering their name
      Then Robin should still not be an active member of West Coast Paddlers
      When Robin follows the same invitation link again
      Then Robin should be asked for their name
      When Robin enters "Robin Example" as their name
      Then Robin should be an active member of West Coast Paddlers

Rule: Staff club-member creation goes through invitations

    Scenario: Pat cannot bypass invitation when adding a club member
      Given Pat is signed in as Memba staff
      And West Coast Paddlers exists as a club
      When Pat wants to add a new member to West Coast Paddlers
      Then Pat should be asked for the member's email address only
      And Pat should not be able to create an active member directly from a name and email address

Rule: An invitation does not create duplicate club membership

    Scenario: Pat cannot invite an active member again
      Given Alice is an active member of West Coast Paddlers
      And Pat is signed in as Memba staff
      When Pat tries to invite Alice to join West Coast Paddlers
      Then Pat should see that Alice is already a member of West Coast Paddlers

    Scenario: Pat resends a pending invitation by inviting the same email again
      Given Pat has invited "robin@example.com" to join West Coast Paddlers
      When Pat invites "robin@example.com" to join West Coast Paddlers again
      Then "robin@example.com" should receive another invitation to join West Coast Paddlers
      And there should still be only one pending invitation for "robin@example.com" to join West Coast Paddlers

    @iteration-029
    Scenario: Robin cannot invite an active member again
      Given Robin is a Membership Admin of West Coast Paddlers
      And Alice is an active member of West Coast Paddlers
      When Robin tries to invite Alice to join West Coast Paddlers
      Then Robin should see that Alice is already a member of West Coast Paddlers

    @iteration-029
    Scenario: Robin resends a pending invitation by inviting the same email again
      Given Robin is a Membership Admin of West Coast Paddlers
      And Robin has invited "dana@example.com" to join West Coast Paddlers
      When Robin invites "dana@example.com" to join West Coast Paddlers again
      Then "dana@example.com" should receive another invitation to join West Coast Paddlers
      And there should still be only one pending invitation for "dana@example.com" to join West Coast Paddlers

Rule: Invitation links can only be accepted once

    Scenario: Robin reopens an accepted invitation
      Given Robin has accepted an invitation to join West Coast Paddlers
      When Robin follows the same invitation link again
      Then Robin should still have only one active membership of West Coast Paddlers
      And Robin should be signed in to West Coast Paddlers
