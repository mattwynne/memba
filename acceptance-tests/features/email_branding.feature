Feature: Email branding
  People receiving Memba emails should recognise Memba and, when a club is involved, the club context.

Rule: Memba transactional emails use consistent Memba branding

    @iteration-031 @todo-domain
    Scenario: Alice receives a branded sign-in email
      Given Alice is a member of Kootenay Mountaineering Club
      When Alice requests a sign-in link for their email address
      Then Alice should receive a sign-in email with the Memba sprig icon
      And the sign-in email should use the standard Memba footer

Rule: Club-message rejection emails identify the club

    @iteration-031 @iteration-042
    Scenario: Robin receives a KMC rejection email
      Given Kootenay Mountaineering Club has the slug "kmc"
      When Robin emails "Trip planning night" to everyone@kmc.clubs.memba.io from "robin@example.test"
      Then Robin should receive a rejection email from "Kootenay Mountaineering Club via Memba"
      And the rejection email should use the standard Memba footer
