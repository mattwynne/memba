Feature: Operator email deliverability
  Operators need to understand which members are having email delivery problems
  so they can keep club communication reliable.

  Background:
    Given Kootenay Mountaineering Club is a club
    And Alice, Bob, and Carol are people
    And Alice, Bob, and Carol are members of Kootenay Mountaineering Club

  Rule: Operators monitor detailed delivery records across messages

    Scenario: Deliveries from different messages appear together
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Alice has sent the message "Avalanche bulletin" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as delayed because "recipient server is temporarily unavailable"
      And Carol's email for "Avalanche bulletin" is reported as bounced because "mailbox does not exist"
      Then operators should see Bob's delivery for "Trip planning night" as "delayed"
      And operators should see Bob's delivery reason "recipient server is temporarily unavailable"
      And operators should see Carol's delivery for "Avalanche bulletin" as "bounced"
      And operators should see Carol's delivery reason "mailbox does not exist"

    Scenario: Spam complaints keep the provider reason
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      When Bob's email for "Trip planning night" is reported as a spam complaint because "recipient marked the message as spam"
      Then operators should see Bob's delivery for "Trip planning night" as "spam complaint"
      And operators should see Bob's delivery reason "recipient marked the message as spam"

    Scenario: Opens are visible after delivery
      Given Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Bob's email for "Trip planning night" has been reported as delivered
      When Bob opens the email for "Trip planning night"
      Then operators should see Bob's delivery for "Trip planning night" as "opened"
