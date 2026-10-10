Feature: Member profile
  Members keep their own name and photo up to date, so their clubs see them as they choose to be seen.

Rule: A Person's current name follows them across clubs and past contributions

    @iteration-068 @todo
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

    @iteration-068 @todo
    Scenario: Alice cannot replace their name with whitespace
      Given Alice is known as "Alice Smith"
      When Alice tries to change their name to "   "
      Then Alice should be told "Enter the name your clubs should see."
      And Alice should be known as "Alice Smith"

Rule: A conflicting stale change must not silently replace a newer name

    @iteration-068 @todo
    Scenario: Alice's older edit requires confirmation of the newer name
      Given Alice began changing their name when it was "Alice Smith"
      And Alice has since changed their name to "Alice Jones"
      When Alice submits the older change to "Alice Brown"
      Then the change should be rejected because their name changed elsewhere
      And Alice should be known as "Alice Jones"
      When Alice confirms replacing "Alice Jones" with "Alice Brown"
      Then Alice should be known as "Alice Brown"

Rule: A member's photo stands in for their initials

    @iteration-069 @todo
    Scenario: Alice adds a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice adds the photo "alice-on-the-summit.jpg"
      Then Alice should see their photo in Account settings
      And Bob should see Alice's photo in the Kootenay Mountaineering Club member list

    @iteration-069 @todo
    Scenario: Alice replaces her photo with a newer one
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice adds the photo "alice-in-the-canoe.jpg"
      Then Alice's photo should be "alice-in-the-canoe.jpg"

    @iteration-069 @todo
    Scenario: Alice removes her photo and goes back to her initials
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice removes their photo
      Then Alice should see their initials in Account settings
      And Bob should see Alice's initials in the Kootenay Mountaineering Club member list

Rule: Only images Memba can display are accepted as photos

    @iteration-069 @todo
    Scenario: Alice picks a document instead of a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add "membership-form.pdf" as their photo
      Then Alice should be told "That file isn't an image we can use. Choose a JPG, PNG, GIF or WebP."
      And Alice should see their initials in Account settings

    @iteration-069 @todo
    Scenario: Alice picks a photo far too big to handle
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add a 40 MB photo
      Then Alice should be told "That photo is bigger than 25 MB. Choose a smaller one."
      And Alice should see their initials in Account settings

Rule: A failed upload leaves the member's existing photo in place

    @iteration-069 @todo
    Scenario: Alice's upload fails part way through
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice's photo upload fails
      Then Alice should be told "We couldn't upload that photo. Please try again."
      And Alice's photo should be "alice-on-the-summit.jpg"

Rule: A member's photo is only visible to people signed in to Memba

    @iteration-069 @todo
    Scenario: A signed-out visitor cannot fetch Alice's photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When a signed-out visitor requests Alice's photo
      Then Memba should not show Alice's photo
