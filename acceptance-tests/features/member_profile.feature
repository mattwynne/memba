Feature: Member profile
  Members keep their own name up to date, so their clubs see them as they choose to be seen.

Rule: A Person's current name follows them across clubs and past contributions

    @iteration-068
    Scenario: Alice's corrected name appears across clubs and on earlier contributions
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is a member of Rockies Cycling Co-op
      And Alice is known as "Alice Smith"
      And Alice started the conversation "Trip planning night" in Kootenay Mountaineering Club
      And Alice replied to the conversation "Summer rides" in Rockies Cycling Co-op
      When Alice changes their name to "Alice Jones"
      Then Alice should be known as "Alice Jones" in Kootenay Mountaineering Club
      And Alice should be known as "Alice Jones" in Rockies Cycling Co-op
      And Alice's earlier conversation "Trip planning night" should show "Alice Jones" as its author
      And Alice's earlier reply to "Summer rides" should show "Alice Jones" as its author

Rule: A Person must have a valid name

    @iteration-068
    Scenario: Alice cannot replace their name with whitespace
      Given Alice is known as "Alice Smith"
      When Alice tries to change their name to "   "
      Then Alice should be told "Enter the name your clubs should see."
      And Alice should be known as "Alice Smith"

Rule: A conflicting stale change must not silently replace a newer name

    @iteration-068
    Scenario: Alice's older edit requires confirmation of the newer name
      Given Alice began changing their name when it was "Alice Smith"
      And Alice has since changed their name to "Alice Jones"
      When Alice submits the older change to "Alice Brown"
      Then the change should be rejected because their name changed elsewhere
      And Alice should be known as "Alice Jones"
      When Alice confirms replacing "Alice Jones" with "Alice Brown"
      Then Alice should be known as "Alice Brown"
