Feature: Authentication
  People use one sign-in form to access the parts of Memba they are allowed to use.

  Rule: Club pages are public until member-only access is needed

    Scenario: Logged-out visitor sees a club marketing page
      Given Alice is a member of Kootenay Mountaineering Club
      When Robin opens the Kootenay Mountaineering Club page
      Then Robin should see the Kootenay Mountaineering Club marketing page
      And the club page should show Powered by Memba in the footer

  Rule: Known club members can sign in

    Scenario: A club member signs in and sees their club
      Given Alice is a member of Kootenay Mountaineering Club
      When Alice requests a sign-in link for their email address
      Then Alice should receive a sign-in link
      When Alice follows the sign-in link
      Then Alice should be signed in
      And Alice should see Kootenay Mountaineering Club in their clubs
      When Alice opens the Kootenay Mountaineering Club page
      Then Alice should see they are signed in on the club page
      And the club page should show Powered by Memba in the footer

    Scenario: A club member with memberships in two clubs sees both clubs
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice is a member of Nelson Paddling Club
      When Alice requests a sign-in link for their email address
      Then Alice should receive a sign-in link
      When Alice follows the sign-in link
      Then Alice should be signed in
      And Alice should see Kootenay Mountaineering Club in their clubs
      And Alice should see Nelson Paddling Club in their clubs

  Rule: Anyone with a memba.io email address can sign in as staff

    Scenario: New Memba staff sign themselves up
      Given Pat is not a member of any club
      When Pat requests a sign-in link for "pat@memba.io"
      Then Pat should receive a sign-in link
      When Pat follows the sign-in link
      Then Pat should be signed in as Memba staff
      And Pat should be on the staff-only homepage

    Scenario: Memba staff who are also club members can use both kinds of access
      Given Pat is a member of Kootenay Mountaineering Club
      When Pat requests a sign-in link for "pat@memba.io"
      Then Pat should receive a sign-in link
      When Pat follows the sign-in link
      Then Pat should be signed in as Memba staff
      And Pat should be on the staff-only homepage
      And Pat should be able to see Kootenay Mountaineering Club in their clubs

  Rule: People who are neither club members nor Memba staff cannot sign in

    Scenario: Unknown person requests a sign-in link
      Given Robin is not a member of any club
      When Robin requests a sign-in link for their email address
      Then Robin should not receive a sign-in link

  Rule: A sign-in link can only be used once

    Scenario: A signed-out person cannot reuse a sign-in link
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has received a sign-in link for their email address
      And Alice has already followed the sign-in link
      And Alice has signed out
      When Alice follows the same sign-in link again
      Then Alice should not be signed in

    Scenario: Reopening a used sign-in link after signing in
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has received a sign-in link for their email address
      And Alice has already followed the sign-in link
      When Alice follows the same sign-in link again
      Then Alice should still be signed in
      And Alice should be on the homepage

  Rule: Expired sign-in links cannot be used

    Scenario: Following an expired sign-in link
      Given Alice is a member of Kootenay Mountaineering Club
      And Alice has received a sign-in link for their email address
      And the sign-in link has expired
      When Alice follows the sign-in link
      Then Alice should not be signed in

  Rule: Invalid sign-in links cannot be used

    Scenario: Following a link that Memba did not issue
      When Robin follows a sign-in link that Memba did not issue
      Then Robin should not be signed in

  Rule: Signing in can continue an interrupted journey

    Scenario: Staff signs in after trying to open the staff-only area
      Given Pat is not a member of any club
      And Pat has tried to open the staff-only area
      When Pat requests a sign-in link for "pat@memba.io"
      Then Pat should receive a sign-in link
      When Pat follows the sign-in link
      Then Pat should be signed in as Memba staff
      And Pat should be on the staff-only homepage

  Rule: Signed-in people can sign out

    Scenario: Staff signs out
      Given Pat is not a member of any club
      When Pat requests a sign-in link for "pat@memba.io"
      Then Pat should receive a sign-in link
      When Pat follows the sign-in link
      Then Pat should be signed in as Memba staff
      When Pat signs out
      Then Pat should be signed out

    Scenario: Club member signs out from a club page
      Given Alice is a member of Kootenay Mountaineering Club
      When Alice requests a sign-in link for their email address
      Then Alice should receive a sign-in link
      When Alice follows the sign-in link
      Then Alice should be signed in
      When Alice opens the Kootenay Mountaineering Club page
      And Alice signs out
      Then Alice should be signed out
