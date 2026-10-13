@journey @iteration-068
Feature: Correcting a name from Account settings

  Rule: A member can correct their name without leaving untouched forms behind


    Scenario: Alice corrects their name while another Profile form is open
      Given Alice is signed in as a member of Kootenay Mountaineering Club
      And Alice is known as "Alice Smith"
      And Alice has an untouched name edit open in another Account settings tab
      When Alice opens Account settings from their member menu
      And Alice edits their Profile name to "Robin Jones" and saves it
      Then Alice should see "Robin Jones" in their Profile and member menu
      And Alice's member menu avatar should show the initials "RJ"
      And the untouched name form in the other tab should show "Robin Jones" without reloading
