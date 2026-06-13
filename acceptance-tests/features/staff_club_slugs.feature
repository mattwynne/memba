Feature: Staff club slugs
  Memba staff prepare clubs for future email addresses and hosted club sites by managing each club's slug.

  Background:
    Given Pat is signed in as Memba staff

Rule: A club gets an address-safe default slug from its name

    Scenario: Staff create a club with the suggested slug
      When Pat starts creating the club "Kootenay Mountaineering Club"
      Then Memba should suggest the slug "kootenay-mountaineering-club"
      When Pat saves the club
      Then Kootenay Mountaineering Club should have the slug "kootenay-mountaineering-club"

Rule: Staff-edited slugs must already be address-safe

    Scenario: Staff enter an invalid slug
      Given Kootenay Mountaineering Club is a club
      When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
      Then Memba should reject the club slug as invalid
      And Kootenay Mountaineering Club should keep its previous slug

Rule: A slug can belong to only one club

    Scenario: Staff enter a slug that another club already uses
      Given Kootenay Mountaineering Club has the slug "kmc"
      And Nelson Paddling Club is a club
      When Pat tries to change Nelson Paddling Club's slug to "kmc"
      Then Memba should reject the club slug as already taken
      And Nelson Paddling Club should keep its previous slug

Rule: A club slug routes public visitors to that club's public page

    @not-domain
    Scenario: Robin opens an unknown club subdomain
      When Robin opens "unknown.clubs.memba.io"
      Then Robin should see a not found page
