defmodule MembaWeb.ClubMemberInvitationsLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  test "routed GET renders the club-scoped member invitation action for a query-selected club", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/members/invitations/new?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-club-member-invitation-new[data-live-view='member-club-member-invitation-new'][data-club-id='#{alice.club_id}'][data-current-member-id='#{alice.person_id}']"
           )

    assert has_element?(
             view,
             "#member-invitation-selected-club[data-club-id='#{alice.club_id}']",
             "Climbing Club"
           )

    assert has_element?(
             view,
             "#member-invitation-club-home-link[href='/?club_id=#{alice.club_id}']",
             "Club home"
           )
  end

  test "club subdomain routed mount scopes the invitation action to the host-selected club", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    _bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "Kootenay Mountaineering Club",
        club_id: alice.club_id,
        slug: "kmc"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-member-invitation-new[data-club-id='#{alice.club_id}'][data-current-member-id='#{alice.person_id}'][data-active-member-count='2']"
           )

    assert has_element?(view, "#member-invitation-club-home-link[href='/']")
    refute has_element?(view, "#member-invitation-club-home-link[href*='club_id=']")
  end

  test "routed GET redirects signed-out visitors and preserves the selected club return path",
       %{conn: conn} do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Climbing Club"
      )

    return_path = ~p"/members/invitations/new?club_id=#{alice.club_id}"

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
