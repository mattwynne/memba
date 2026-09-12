defmodule MembaWeb.MemberUIContractTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @moduledoc """
  Cross-screen member UI contracts approved by the HEEx simplification review.

  These tests intentionally exercise routed LiveViews and semantic IDs instead of
  private components. They may be red on the original baseline until the related
  UI implementation streams land.
  """

  @tag pending_dependency: :goal2_audience
  test "a selected group compose action opens a composer for that group audience", %{conn: conn} do
    %{alice: alice, bob: _bob, carol: _carol, group: trail_crew} =
      club_with_trail_crew(group_member_count: 2)

    expected_group_address = group_address(alice.club_id, trail_crew.email_slug)

    {:ok, dashboard, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/groups/#{trail_crew.group_id}")

    assert has_element?(dashboard, "#member-group-name", "Trail Crew")

    assert has_element?(
             dashboard,
             "#member-section-action-new-message[href='/messages/new?group_id=#{trail_crew.group_id}']"
           )

    compose_href =
      dashboard
      |> render()
      |> only_attribute!("#member-section-action-new-message", "href")

    {:ok, composer, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(compose_href)

    assert has_element?(
             composer,
             "#member-message-compose" <>
               "[data-audience-group-id='#{trail_crew.group_id}']" <>
               "[data-active-member-count='2']"
           )

    assert has_element?(
             composer,
             "#member-compose-recipient-summary[data-active-member-count='2']",
             "Trail Crew"
           )

    refute has_element?(composer, "#member-compose-recipient-summary", "3 current members")
    refute has_element?(composer, "#member-compose-recipient-summary", "club-wide")

    assert has_element?(
             composer,
             "#member-compose-inbound-email[data-inbound-address='#{expected_group_address}']"
           )

    assert has_element?(
             composer,
             "#member-compose-inbound-email-link[href='mailto:#{expected_group_address}']",
             expected_group_address
           )

    refute has_element?(composer, "#member-compose-inbound-email", "club-wide")
  end

  @tag pending_dependency: :goal1_tab_actions
  test "switching a manager to group members shows the invite action without the compose action", %{
    conn: conn
  } do
    %{alice: alice, group: trail_crew} = club_with_trail_crew(group_member_count: 2)
    grant_manage_members!(alice)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/groups/#{trail_crew.group_id}")

    assert has_element?(
             view,
             "#member-section-action-new-message[href='/messages/new?group_id=#{trail_crew.group_id}']"
           )

    refute has_element?(view, "#member-section-action-invite-member")

    view
    |> element("#member-section-tab-members")
    |> render_click()

    assert_patch(view, ~p"/groups/#{trail_crew.group_id}/members")
    refute has_element?(view, "#member-section-action-new-message")

    assert has_element?(
             view,
             "#member-section-action-invite-member" <>
               "[href='/members/invitations/new?group_id=#{trail_crew.group_id}']"
           )
  end

  @tag pending_dependency: :goal1_tab_actions
  test "switching an ordinary member to group members leaves member actions hidden", %{conn: conn} do
    %{bob: bob, group: trail_crew} = club_with_trail_crew(group_member_count: 2)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", bob)
      |> live(~p"/groups/#{trail_crew.group_id}")

    view
    |> element("#member-section-tab-members")
    |> render_click()

    assert_patch(view, ~p"/groups/#{trail_crew.group_id}/members")
    refute has_element?(view, "#member-section-action-new-message")
    refute has_element?(view, "#member-section-action-invite-member")
  end

  @tag pending_dependency: :remove_member_blank_slate
  test "a one-member group members screen keeps the member row without a promotional empty banner", %{
    conn: conn
  } do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    solo_group =
      create_group(
        club_id: alice.club_id,
        group_key: "solo_paddlers",
        email_slug: "solo-paddlers",
        name: "Solo Paddlers"
      )

    add_group_member(solo_group, alice)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", alice)
      |> live(~p"/groups/#{solo_group.group_id}/members")

    assert has_element?(
             view,
             "#active-members-list[data-active-member-count='1'] " <>
               "#club-member-#{alice.person_id}[data-testid='club-member-row'] .member-row__name",
             "Alice Adams"
           )

    refute has_element?(view, "#active-members-empty-state")
    refute has_element?(view, "#active-members-list", "You’re the first member listed")
    refute has_element?(view, "#active-members-list", "As members are added")
  end

  defp club_with_trail_crew(opts) do
    alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "West Coast Paddlers"
      )

    bob =
      create_active_member(
        email: "bob@example.com",
        name: "Bob Builder",
        club_name: "West Coast Paddlers",
        club_id: alice.club_id
      )

    carol =
      create_active_member(
        email: "carol@example.com",
        name: "Carol Canoe",
        club_name: "West Coast Paddlers",
        club_id: alice.club_id
      )

    trail_crew =
      create_group(
        club_id: alice.club_id,
        group_key: "trail_crew",
        email_slug: "trail-crew",
        name: "Trail Crew"
      )

    add_group_member(trail_crew, alice)
    add_group_member(trail_crew, bob)

    if Keyword.fetch!(opts, :group_member_count) == 3 do
      add_group_member(trail_crew, carol)
    end

    %{alice: alice, bob: bob, carol: carol, group: trail_crew}
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)
    club_name = Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club")

    Repo.get(Club, club_id) ||
      attrs
      |> club_attrs(club_id, club_name)
      |> insert_membership_club!()

    person =
      insert_membership_person!(
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name),
        email: Keyword.fetch!(attrs, :email)
      )

    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%Membership{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    insert_everyone_group_membership!(club_id, membership_id, person.person_id)

    %{club_id: club_id, membership_id: membership_id, person_id: person.person_id}
  end

  defp insert_everyone_group_membership!(club_id, membership_id, person_id) do
    group_id = SystemGroups.everyone_group_id(club_id)

    Repo.insert!(
      %Group{
        club_id: club_id,
        group_id: group_id,
        group_key: SystemGroups.everyone_key(),
        name: SystemGroups.everyone_name()
      },
      on_conflict: :nothing
    )

    Repo.insert!(%GroupMembership{
      club_id: club_id,
      group_id: group_id,
      membership_id: membership_id,
      person_id: person_id,
      active: true
    })
  end

  defp create_group(attrs) do
    Repo.insert!(%Group{
      club_id: Keyword.fetch!(attrs, :club_id),
      group_id: Memba.ID.generate(:group),
      group_key: Keyword.fetch!(attrs, :group_key),
      email_slug: Keyword.get(attrs, :email_slug),
      name: Keyword.fetch!(attrs, :name)
    })
  end

  defp add_group_member(group, member) do
    Repo.insert!(%GroupMembership{
      club_id: member.club_id,
      group_id: group.group_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      active: true
    })
  end

  defp grant_manage_members!(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp group_address(club_id, group_email_slug) do
    club_id
    |> Memba.Membership.get_club()
    |> Memba.ClubInboundEmailAddress.address(group_email_slug)
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    club = Memba.Membership.get_club(club.club_id) || club
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp club_attrs(attrs, club_id, club_name) do
    base = [
      club_id: club_id,
      name: club_name
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end

  defp only_attribute!(html, selector, attribute) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(attribute)
    |> case do
      [value] -> value
      values -> flunk("expected one #{attribute} for #{selector}, got #{inspect(values)}")
    end
  end
end
