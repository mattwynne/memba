# Discovery material only: moved out of the acceptance suite on 2026-10-22.
# No iteration is assigned and these examples are not approved delivery work.
Feature: Profile photo draft examples

Rule: A member's photo stands in for their initials

    Scenario: Alice adds a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice adds the photo "alice-on-the-summit.jpg"
      Then Alice should see their photo in Account settings
      And Bob should see Alice's photo in the Kootenay Mountaineering Club member list

    Scenario: Alice replaces her photo with a newer one
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice adds the photo "alice-in-the-canoe.jpg"
      Then Alice's photo should be "alice-in-the-canoe.jpg"

    Scenario: Alice removes her photo and goes back to her initials
      Given Alice is a member of Kootenay Mountaineering Club
      And Bob is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice removes their photo
      Then Alice should see their initials in Account settings
      And Bob should see Alice's initials in the Kootenay Mountaineering Club member list

Rule: Only images Memba can display are accepted as photos

    Scenario: Alice picks a document instead of a photo
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add "membership-form.pdf" as their photo
      Then Alice should be told "That file isn't an image we can use. Choose a JPG, PNG, GIF or WebP."
      And Alice should see their initials in Account settings

    Scenario: Alice picks a photo far too big to handle
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has no photo
      When Alice tries to add a 40 MB photo
      Then Alice should be told "That photo is bigger than 25 MB. Choose a smaller one."
      And Alice should see their initials in Account settings

Rule: A failed upload leaves the member's existing photo in place

    Scenario: Alice's upload fails part way through
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has the photo "alice-on-the-summit.jpg"
      When Alice's photo upload fails
      Then Alice should be told "We couldn't upload that photo. Please try again."
      And Alice's photo should be "alice-on-the-summit.jpg"
