Feature: Member profile
  Members keep their own name and photo up to date, so their clubs see them as they choose to be seen.

Rule: A member can change their own name

    @iteration-054 @todo-domain @todo-ui
    Scenario: Alice corrects the name her clubs see
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is known as "Alice Smith"
      When Alice changes their name to "Alice Jones"
      Then Alice should be known as "Alice Jones"

    @iteration-054 @todo-domain @todo-ui
    Scenario: Alice's new name replaces her old one everywhere her club sees her
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice is known as "Alice Smith"
      And Alice started the conversation "Trip planning night"
      When Alice changes their name to "Alice Jones"
      Then Bob should see "Alice Jones" in the Kootenay Mountaineering Club member list
      And Bob should see "Trip planning night" as started by "Alice Jones"

    @iteration-054 @todo-domain @todo-ui
    Scenario: Alice's new name follows her to every club she belongs to
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is a member of Rockies Cycling Co-op
      And Alice is known as "Alice Smith"
      When Alice changes their name to "Alice Jones"
      Then Alice should be known as "Alice Jones" in Kootenay Mountaineering Club
      And Alice should be known as "Alice Jones" in Rockies Cycling Co-op

Rule: A member must have a name

    @iteration-054 @todo-domain @todo-ui
    Scenario: Alice cannot leave her name blank
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is known as "Alice Smith"
      When Alice tries to change their name to ""
      Then Alice should be told "Enter the name your clubs should see."
      And Alice should be known as "Alice Smith"

Rule: A member's photo stands in for their initials

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice adds a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice adds the photo "alice-on-the-summit.jpg"
      Then Alice should see their photo in Account settings
      And Bob should see Alice's photo in the Kootenay Mountaineering Club member list

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice replaces her photo with a newer one
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice adds the photo "alice-in-the-canoe.jpg"
      Then Alice's photo should be "alice-in-the-canoe.jpg"

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice removes her photo and goes back to her initials
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice removes their photo
      Then Alice should see their initials in Account settings
      And Bob should see Alice's initials in the Kootenay Mountaineering Club member list

Rule: Only images Memba can display are accepted as photos

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice picks a document instead of a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add "membership-form.pdf" as their photo
      Then Alice should be told "That file isn't an image we can use. Choose a JPG, PNG, GIF or WebP."
      And Alice should see their initials in Account settings

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice picks a photo far too big to handle
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add a 40 MB photo
      Then Alice should be told "That photo is bigger than 25 MB. Choose a smaller one."
      And Alice should see their initials in Account settings

Rule: A failed upload leaves the member's existing photo in place

    @iteration-055 @todo-domain @todo-ui
    Scenario: Alice's upload fails part way through
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice's photo upload fails
      Then Alice should be told "We couldn't upload that photo. Please try again."
      And Alice's photo should be "alice-on-the-summit.jpg"

Rule: A member's photo is only visible to people signed in to Memba

    @iteration-055 @todo-domain @todo-ui
    Scenario: A signed-out visitor cannot fetch Alice's photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When a signed-out visitor requests Alice's photo
      Then Memba should not show Alice's photo
