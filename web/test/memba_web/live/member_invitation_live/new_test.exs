defmodule MembaWeb.MemberInvitationLive.NewTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Memba.Accounts.AuthEmail
  alias Memba.Membership
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo
  alias MembaWeb.IdentityAuth

  setup :set_swoosh_global

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "test-auth"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

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

    assert has_element?(view, "#member-invitation-form[aria-label='Invite member']")

    assert has_element?(
             view,
             "#member-invitation-email-input[aria-label='Invitee email address']"
           )

    assert has_element?(view, "#send-member-invitation-button")
    refute has_element?(view, "#person-name-input")
    refute has_element?(view, "input[name='invitation[name]']")
    refute has_element?(view, "select[name='invitation[role]']")
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

  test "submitting a member invitation keeps the Membership Admin form email-only", %{
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

    render_submit(view, "send_invitation", %{
      "invitation" => %{
        "email" => " DANA@Example.COM ",
        "name" => "Dana Danger",
        "role" => "membership_administrator"
      }
    })

    assert has_element?(view, "#flash-info", "Invitation sent to dana@example.com")

    assert %ClubInvitation{
             club_id: club_id,
             email: "dana@example.com",
             normalized_email: "dana@example.com",
             status: "pending"
           } =
             Membership.get_pending_club_member_invitation_by_email(
               alice.club_id,
               "dana@example.com"
             )

    assert club_id == alice.club_id
    refute Membership.get_person_by_email("dana@example.com")
    refute Membership.active_member_of_club_by_email?(alice.club_id, "dana@example.com")

    assert_email_sent(fn email ->
      assert email.to == [{"", "dana@example.com"}]
      assert email.subject == "You're invited to join Alpine Club"
      assert email.text_body =~ "/invitations/club-members/"
    end)
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

  test "direct LiveView access forbids an ordinary member before any crafted event can run", %{
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
      |> live(~p"/members/invitations/new?club_id=#{alice.club_id}")
    end
  end

  test "host-selected direct access forbids an ordinary member", %{conn: conn} do
    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_name: "Kootenay Mountaineering Club",
        slug: "kmc"
      )

    assert_raise MembaWeb.ForbiddenError, fn ->
      conn
      |> Map.put(:host, "kmc.lvh.me")
      |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
      |> get(~p"/members/invitations/new")
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
      Repo.insert!(%MembershipProjection{
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

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

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
