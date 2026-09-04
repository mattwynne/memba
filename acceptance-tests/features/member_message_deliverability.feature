Feature: Member message deliverability
  Club members need confidence that important club messages are reaching other members.
  Memba shows simple receipt-style feedback to regular members.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Nelson Paddling Club is a club
    And Alice, Bob, Carol, and Dana are people
    And Pat is a person
    And Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club
    And Pat is a member of Nelson Paddling Club

Rule: Any member can send a message to every active member of their club

    Scenario: Alice sends a club message
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
      And Alice should see the message was addressed to Alice, Bob, Carol, and Dana
      And Alice should not see Pat in the addressed members
      And Alice should see every addressed member's status as "Sending"
      And each addressed member should receive an email from Alice via Memba

Rule: Club-message emails identify the club in the subject

    Scenario: Alice's club-message email subject includes the club slug
      When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
      Then each addressed member should receive an email with the subject "[kmc] Trip planning night"
      And Alice should see the message "Trip planning night" in Kootenay Mountaineering Club

Rule: Members see simple statuses for everyone addressed

    Scenario: Alice sees different statuses for different members
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      And Carol's email for "Trip planning night" has been reported as bounced because "mailbox does not exist"
      When Alice views the message "Trip planning night"
      Then Alice should see Bob's status for "Trip planning night" as "Delivered"
      And Alice should see Carol's status for "Trip planning night" as "Delivery problem"
      And Alice should see Dana's status for "Trip planning night" as "Sending"
      And Alice should see Alice's status for "Trip planning night" as "Sending"

    Scenario: Bob sees the same shared statuses
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      And Carol's email for "Trip planning night" has been reported as delayed because "recipient server is temporarily unavailable"
      When Bob views the message "Trip planning night"
      Then Bob should see Alice's status for "Trip planning night" as "Sending"
      And Bob should see Bob's status for "Trip planning night" as "Delivered"
      And Bob should see Carol's status for "Trip planning night" as "Delivery problem"

Rule: Members are told when a club message is not sent

    Scenario: Alice is told a failed message was not sent
      Given club message sending is unavailable
      When Alice tries to send the message "Trip planning night" to Kootenay Mountaineering Club members
      Then Alice should be told the message was not sent
      And Alice should be told to contact support

    Scenario: Alice leaves the message body blank
      When Alice tries to send a message to Kootenay Mountaineering Club members with subject "Trip planning night" and no body
      Then Alice should be told the message body cannot be blank
      And no club message named "Trip planning night" should be created
      And no addressed member should receive an email for "Trip planning night"

Rule: Active members can send new club messages by email

    @iteration-042
    Scenario: Alice emails the KMC everyone address
      When Alice emails "Trip planning night" to everyone@kmc.clubs.memba.io
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
      And Alice should see the message was addressed to Alice, Bob, Carol, and Dana
      And Alice should not see Pat in the addressed members
      And each addressed member should receive an email from Alice via Memba

    @iteration-042
    Scenario: Alice emails from an alternate address
      Given Alice's alternate email address is "alice.outdoors@example.test"
      When Alice emails "Trip planning night" to everyone@kmc.clubs.memba.io from "alice.outdoors@example.test"
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
      And each addressed member should receive an email from Alice via Memba

Rule: Active club members can start a private Admin conversation by email

    @iteration-057 @todo-domain @todo-ui
    Scenario: Alice emails the KMC Admin address without belonging to Admin
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Alice emails "Committee meeting" to admin@kmc.clubs.memba.io
      Then Bob and Carol should each receive the Admin message "Committee meeting" by email from Kootenay Mountaineering Club via Memba
      And Alice should not receive the Admin message "Committee meeting" by email
      And Alice and Bob should not see the Admin message "Committee meeting" in the Kootenay Mountaineering Club web app

    @iteration-057 @todo-domain @todo-ui
    Scenario: Bob emails the KMC Admin address as an Admin member
      Given Bob and Carol are members of the Kootenay Mountaineering Club Admin group
      When Bob emails "Committee meeting" to admin@kmc.clubs.memba.io
      Then Bob and Carol should each receive the Admin message "Committee meeting" by email from Kootenay Mountaineering Club via Memba
      And Alice should not receive the Admin message "Committee meeting" by email

    @iteration-057 @todo-domain @todo-ui
    Scenario: A member of another club emails the KMC Admin address
      When Pat emails "Committee meeting" to admin@kmc.clubs.memba.io
      Then no Kootenay Mountaineering Club Admin message named "Committee meeting" should be created
      And Pat should receive a rejection email explaining the message was not posted
      And Pat should be told how to contact support

Rule: Only the everyone route on a known club email subdomain is accepted

    @iteration-042
    Scenario: Alice emails an unsupported route on KMC's club email subdomain
      When Alice emails "Trip planning night" to committee@kmc.clubs.memba.io
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Alice should receive a rejection email explaining the message was not posted
      And Alice should be told how to contact support

    @iteration-042
    Scenario: Alice emails an unknown club subdomain
      When Alice emails "Trip planning night" to everyone@unknown.clubs.memba.io
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Alice should receive a rejection email explaining the message was not posted
      And Alice should be told how to contact support

    @iteration-042
    Scenario: Alice emails the old flat club address after the cutover
      When Alice emails "Trip planning night" to kmc@clubs.memba.io
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Alice should receive a rejection email explaining the message was not posted
      And Alice should be told how to contact support

Rule: Inbound club email is rejected when it cannot be posted safely

    @iteration-042
    Scenario: An unknown sender emails the KMC everyone address
      When Robin emails "Trip planning night" to everyone@kmc.clubs.memba.io from "robin@example.test"
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Robin should receive a rejection email explaining the message was not posted
      And Robin should be told how to contact support

    @iteration-042
    Scenario: A member of another club emails the KMC everyone address
      When Pat emails "Trip planning night" to everyone@kmc.clubs.memba.io
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Pat should receive a rejection email explaining the message was not posted
      And Pat should be told how to contact support

    @iteration-042
    Scenario: Alice emails an attachment to the KMC everyone address
      When Alice emails "Trip planning night" to everyone@kmc.clubs.memba.io with an attachment
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Alice should receive a rejection email explaining attachments are not supported
      And Alice should be told how to contact support

    @iteration-042
    Scenario: Alice emails without a plain-text message body
      When Alice emails "Trip planning night" to everyone@kmc.clubs.memba.io with only an HTML body
      Then no Kootenay Mountaineering Club message named "Trip planning night" should be created
      And Alice should receive a rejection email explaining a plain-text message body is required
      And Alice should be told how to contact support

Rule: Inbound club email body keeps only the sender's new plain-text message

    @iteration-042
    Scenario: Alice emails new text above a signature and quoted message
      When Alice emails "Trip planning night" to everyone@kmc.clubs.memba.io with the body:
        """
        Let's meet at 7pm in the clubhouse.

        --
        Alice

        On Monday, Bob wrote:
        > Can we meet this week?
        """
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club
      And the message body should be:
        """
        Let's meet at 7pm in the clubhouse.
        """
