defmodule MembaWeb.MemberMessageLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Repo
  alias MembaWeb.UserAuth

  test "renders a member message compose LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberMessageLive.New)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")
    assert has_element?(view, "#member-message-compose[data-live-view='member-message-compose']")
  end

  test "routed GET keeps the compose URL shape and passes club_id to the LiveView", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/new?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}'][data-live-view='member-message-compose']"
           )
  end

  test "routed mount derives compose context from the signed-in member and selected club", %{
    conn: conn
  } do
    _other_alice_club =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Book Club"
      )

    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Climbing Club",
        club_id: alice.club_id
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/new?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-message-compose[data-club-id='#{alice.club_id}'][data-current-member-id='#{alice.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(
             view,
             "#member-compose-selected-club[data-club-id='#{alice.club_id}']",
             "Climbing Club"
           )

    assert has_element?(
             view,
             "#member-compose-from-summary[data-sender-id='#{alice.person_id}']",
             "Alice Adams"
           )

    refute has_element?(view, "#member-compose-from-summary[data-sender-id='#{bob.person_id}']")

    assert has_element?(
             view,
             "#member-compose-recipient-summary[data-active-member-count='2']"
           )

    assert has_element?(view, "form#member-message-compose-form")
    assert has_element?(view, "input#member-message-subject-input[name='message[subject]']")
    assert has_element?(view, "textarea#member-message-body-input[name='message[body]']")
    refute has_element?(view, "[name='message[sender_id]']")
  end

  test "routed GET forbids a signed-in identity outside the selected club", %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    conn =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "pat@example.com"})
      |> get(~p"/messages/new?club_id=#{alice.club_id}")

    assert response(conn, 403) == "Forbidden"
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)
    person_id = Ecto.UUID.generate()

    Repo.get(Club, club_id) ||
      Repo.insert!(%Club{
        club_id: club_id,
        name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
      })

    Repo.insert!(%Person{
      person_id: person_id,
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    })

    Repo.insert!(%Membership{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: person_id,
      active: true
    })

    %{club_id: club_id, person_id: person_id}
  end
end
