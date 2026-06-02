defmodule MembaWeb.AdminPeopleLiveTest do
  use MembaWeb.FeatureCase, async: false

  test "staff can open the dedicated new-person LiveView for a club", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/people/new")
    |> assert_path("/admin/clubs/*/people/new")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has("#person-new[data-club-id='#{club.club_id}']")
    |> assert_has("#back-to-club-link[href='/admin/clubs/#{club.club_id}']")
    |> assert_has("#person-form[aria-label='Create person']")
    |> assert_has("#person-name-input[aria-label='Person name']")
    |> assert_has("#person-email-addresses[aria-label='Email addresses']")
  end

  test "staff can open the dedicated edit-person LiveView for a club person", %{conn: conn} do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club")
    person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")

    insert_membership_person_email_address!(
      person_id: person.person_id,
      email: "alice@work.example",
      is_primary: false
    )

    conn
    |> sign_in_staff()
    |> visit(~p"/admin/clubs/#{club.club_id}/people/#{person.person_id}/edit")
    |> assert_path("/admin/clubs/*/people/*/edit")
    |> assert_has("#admin-layout[data-surface='admin']")
    |> assert_has(
      "#person-edit[data-club-id='#{club.club_id}'][data-person-id='#{person.person_id}']"
    )
    |> assert_has("#back-to-club-link[href='/admin/clubs/#{club.club_id}']")
    |> assert_has("#person-form[aria-label='Edit person']")
    |> assert_has("#person-name-input[aria-label='Person name']")
    |> assert_has("#person-email-addresses[aria-label='Email addresses']")
    |> assert_has(
      "#person-email-addresses [data-testid='person-email-address'][data-primary='true']",
      text: "alice@example.com"
    )
    |> assert_has(
      "#person-email-addresses [data-testid='person-email-address'][data-primary='false']",
      text: "alice@work.example"
    )
  end
end
