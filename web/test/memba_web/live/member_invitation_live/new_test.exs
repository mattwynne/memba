defmodule MembaWeb.MemberInvitationLive.NewTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  test "renders a member invitation LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberInvitationLive.New)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-live-view='member-club-invitation-new']"
           )
  end

  test "routed GET keeps the invitation URL shape and passes club_id to the LiveView", %{
    conn: conn
  } do
    alice =
      create_membership_admin(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/members/invitations/new?club_id=#{alice.club_id}")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-club-id='#{alice.club_id}'][data-live-view='member-club-invitation-new']"
           )

    assert has_element?(
             view,
             "#member-invitation-selected-club[data-club-id='#{alice.club_id}']",
             "Alpine Club"
           )

    assert has_element?(
             view,
             "#member-invitation-club-home-link[href='/?club_id=#{alice.club_id}']",
             "Club home"
           )
  end

  test "club subdomain routed mount keeps the host-selected club after LiveView connects", %{
    conn: conn
  } do
    alice =
      create_membership_admin(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/members/invitations/new")

    assert has_element?(
             view,
             "#member-club-invitation-new[data-club-id='#{alice.club_id}'][data-club-id-source='host']"
           )

    assert has_element?(view, "#member-invitation-club-home-link[href='/']")
    refute has_element?(view, "#member-invitation-club-home-link[href*='club_id=']")
  end

  test "routed GET forbids an active club member without club.manage_members permission", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/members/invitations/new?club_id=#{alice.club_id}")
    end
  end

  test "routed GET forbids a member whose manage-members permission belongs to another club", %{
    conn: conn
  } do
    selected_club_member =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Alpine Club"
      )

    other_club_admin =
      create_membership_admin(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Backcountry Club"
      )

    refute other_club_admin.club_id == selected_club_member.club_id

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/members/invitations/new?club_id=#{selected_club_member.club_id}")
    end
  end

  defp create_membership_admin(attrs) do
    attrs
    |> create_active_member()
    |> grant_manage_members_permission!()
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

    membership =
      Repo.insert!(%Membership{
        membership_id: Memba.ID.generate(:membership),
        club_id: club_id,
        person_id: person.person_id,
        active: true
      })

    %{club_id: club_id, person_id: person.person_id, membership_id: membership.membership_id}
  end

  defp grant_manage_members_permission!(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })

    member
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
