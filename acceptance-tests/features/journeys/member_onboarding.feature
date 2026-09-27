@journey
Feature: A new member joins a club and returns through email sign-in

  Scenario: Alice joins Kootenay, signs back in, and returns to a private message
    Given Kootenay Mountaineering Club has the slug "kmc"
    And Pat has invited "alice@example.com" to join Kootenay Mountaineering Club
    Then "alice@example.com" should receive an invitation to join Kootenay Mountaineering Club
    When Alice accepts the invitation as "Alice Example"
    Then Alice should be an active member of Kootenay Mountaineering Club
    And Alice should be signed in to Kootenay Mountaineering Club
    When Alice signs out
    Then Alice should be signed out
    When Alice visits the Memba homepage
    And Alice signs in with their email address
    Then Alice should be signed in
    And Alice should see Kootenay Mountaineering Club in their clubs
    When Alice opens Kootenay Mountaineering Club from her clubs
    Then Alice should be on "kmc.clubs.memba.io"
    And Alice should see the Kootenay Mountaineering Club member dashboard
    When Alice sends the message "Trip planning night" to Kootenay Mountaineering Club members
    And Alice signs out
    And Alice opens the private message URL on "kmc.clubs.memba.io" while signed out
    And Alice signs in
    Then Alice should return to the private message URL on "kmc.clubs.memba.io"
