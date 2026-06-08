defmodule MembaWeb.MemberInvitationLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  test "routed GET keeps the member invitation URL shape and passes club_id to the LiveView",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "robin@example.com"})
      |> live(~p"/members/invitations/new?club_id=#{robin.club_id}")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-live-view='member-club-invitation-new'][data-club-id='#{robin.club_id}'][data-current-member-id='#{robin.person_id}']"
           )

    assert has_element?(
             view,
             "#member-club-invitation-selected-club[data-club-id='#{robin.club_id}']",
             "West Coast Paddlers"
           )

    assert has_element?(
             view,
             "#member-club-invitation-club-home-link[href='/?club_id=#{robin.club_id}']",
             "Club home"
           )
  end

  test "club subdomain routed mount keeps the host-selected club after LiveView connects", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers",
        club_id: robin.club_id,
        slug: "wcp"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "robin@example.com"})
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-club-id='#{robin.club_id}'][data-current-member-id='#{robin.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(view, "#member-club-invitation-club-home-link[href='/']")
    refute has_element?(view, "#member-club-invitation-club-home-link[href*='club_id=']")
  end

  test "routed GET redirects signed-out visitors and preserves the selected club return path",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    return_path = ~p"/members/invitations/new?club_id=#{robin.club_id}"

    conn = get(conn, return_path)

    assert redirected_to(conn) == ~p"/auth"
    assert get_session(conn, IdentityAuth.return_to_session_key()) == return_path
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)

    Repo.get(Club, club_id) ||
      attrs
      |> club_attrs(club_id)
      |> insert_membership_club!()

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    %{club_id: club_id, person_id: person.person_id}
  end

  defp club_attrs(attrs, club_id) do
    base = [
      club_id: club_id,
      name: Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end
end
