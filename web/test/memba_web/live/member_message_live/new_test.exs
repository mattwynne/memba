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

  defp create_active_member(attrs) do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

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
