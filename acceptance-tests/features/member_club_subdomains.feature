Feature: Member club subdomains
  Club members use their club's slug subdomain as the home for member-only club pages.

Rule: Club members reach their club from the club slug subdomain

    @not-domain
    Scenario: Alice opens Kootenay Mountaineering Club from her clubs
      Given Alice is a member of Kootenay Mountaineering Club
      And Kootenay Mountaineering Club has the slug "kmc"
      When Alice signs in
      And Alice opens Kootenay Mountaineering Club from her clubs
      Then Alice should be on "kmc.clubs.memba.io"
      And Alice should see the Kootenay Mountaineering Club member dashboard

Rule: The club subdomain selects the club for member-only pages

    @not-domain
    Scenario: Alice composes a message on the Kootenay Mountaineering Club subdomain
      Given Alice is a member of Kootenay Mountaineering Club
      And Kootenay Mountaineering Club has the slug "kmc"
      When Alice starts a message on "kmc.clubs.memba.io"
      Then the message should be addressed to Kootenay Mountaineering Club members

    @not-domain
    Scenario: Alice views a message on the Kootenay Mountaineering Club subdomain
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Kootenay Mountaineering Club has the slug "kmc"
      When Alice views the message "Trip planning night" on "kmc.clubs.memba.io"
      Then Alice should see the message "Trip planning night" in Kootenay Mountaineering Club

Rule: Private member URLs require membership

    @not-domain
    Scenario: Alice signs in after opening a private club message URL
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Kootenay Mountaineering Club has the slug "kmc"
      When Alice opens the private message URL on "kmc.clubs.memba.io" while signed out
      And Alice signs in
      Then Alice should return to the private message URL on "kmc.clubs.memba.io"

    @not-domain
    Scenario: Pat cannot view another club's private message URL
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has sent the message "Trip planning night" to Kootenay Mountaineering Club members
      And Pat is a member of Nelson Paddling Club
      And Kootenay Mountaineering Club has the slug "kmc"
      When Pat opens the private message URL on "kmc.clubs.memba.io"
      Then Pat should see that they are not allowed to view it

Rule: Public club pages remain public at the club subdomain root

    @not-domain
    Scenario: Robin opens the public club page
      Given Kootenay Mountaineering Club has the slug "kmc"
      When Robin opens "kmc.clubs.memba.io"
      Then Robin should see the Kootenay Mountaineering Public club page
      And the club page should show Powered by Memba in the footer

Rule: Club pages offer a path back to Memba

    @iteration-031 @not-domain
    Scenario: Robin returns from a club page to Memba
      Given Kootenay Mountaineering Club has the slug "kmc"
      When Robin opens "kmc.clubs.memba.io"
      Then Robin should see a link to the Memba homepage

Rule: Memba keeps a smoke-test club available without publishing it

    @not-domain
    Scenario: Staff can see the smoke-test club
      Given the smoke-test club has been seeded
      And Pat is signed in as Memba staff
      Then Pat should see Smoke Test Club in the staff club list

    @not-domain
    Scenario: Robin cannot open the smoke-test club public page
      Given the smoke-test club has been seeded
      When Robin opens "test.clubs.memba.io"
      Then Robin should see a not found page
      And Robin should not see the Smoke Test Club public page

    @not-domain
    Scenario: Robin does not see the smoke-test club on the Memba homepage
      Given the smoke-test club has been seeded
      When Robin visits the Memba homepage
      Then Robin should not see Smoke Test Club
