defmodule MembaWeb.MemberInvitationLive.SendTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions
  import Ecto.Query

  alias Memba.Accounts.AuthEmail
  alias Memba.Membership
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo
  alias MembaWeb.ClubSite
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

  test "membership admin invitation uses the shared one-use email and profile completion lifecycle",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers",
        slug: "wcp"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> Map.put(:host, "wcp.lvh.me")
      |> Plug.Test.init_test_session(%{
        IdentityAuth.identity_session_key() => "robin@example.com"
      })
      |> live(~p"/members/invitations/new")

    view
    |> form("#member-club-invitation-form", invitation: %{email: " DANA@Example.COM "})
    |> render_submit()

    assert has_element?(view, "#flash-info", "Invitation sent to dana@example.com")

    assert %ClubInvitation{
             club_id: club_id,
             email: "dana@example.com",
             normalized_email: "dana@example.com",
             status: "pending"
           } =
             Membership.get_pending_club_member_invitation_by_email(
               robin.club_id,
               "dana@example.com"
             )

    assert club_id == robin.club_id
    refute Membership.get_person_by_email("dana@example.com")
    refute Membership.active_member_of_club_by_email?(robin.club_id, "dana@example.com")

    invitation_path = delivered_invitation_path!("dana@example.com")

    new_browser_conn()
    |> visit(invitation_path)
    |> assert_path(~p"/invitations/club-members/profile")
    |> assert_has("section#club-member-profile-completion[data-club-id='#{robin.club_id}']")
    |> fill_in("Your name", with: " Dana Example ")
    |> click_button("Join West Coast Paddlers")
    |> assert_path(~p"/conversations")
    |> assert_has("#member-club-home[data-club-id='#{robin.club_id}']")
    |> assert_has("#club-site-identity-menu .app-menu__who-name", "Dana Example")
    |> assert_has("#member-section-tab-conversations[aria-selected='true']", "Conversations")

    assert %{person_id: dana_person_id, name: "Dana Example", email: "dana@example.com"} =
             Membership.get_person_by_email("dana@example.com")

    assert %MembershipProjection{active: true, person_id: ^dana_person_id} =
             active_membership(robin.club_id, dana_person_id)

    assert Membership.active_member_of_club_by_email?(robin.club_id, "dana@example.com")

    refute Membership.person_has_club_permission?(
             robin.club_id,
             dana_person_id,
             Permissions.club_manage_members()
           )

    refute member_permission?(
             robin.club_id,
             dana_person_id,
             Permissions.club_manage_members()
           )
  end

  test "membership admin duplicate pending invitation resends through the shared invitation rule",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    view
    |> form("#member-club-invitation-form", invitation: %{email: "dana@example.com"})
    |> render_submit()

    first_invitation_path = delivered_invitation_path!("dana@example.com")

    view
    |> form("#member-club-invitation-form", invitation: %{email: " DANA@example.com "})
    |> render_submit()

    assert has_element?(view, "#flash-info", "Invitation resent to dana@example.com")

    assert %ClubInvitation{resend_count: 1} =
             Membership.get_pending_club_member_invitation_by_email(
               robin.club_id,
               "dana@example.com"
             )

    assert 1 ==
             Repo.aggregate(
               from(invitation in ClubInvitation,
                 where:
                   invitation.club_id == ^robin.club_id and
                     invitation.normalized_email == "dana@example.com"
               ),
               :count
             )

    second_invitation_path = delivered_invitation_path!("dana@example.com")
    refute second_invitation_path == first_invitation_path
  end

  test "membership admin cannot invite an already active member through the shared duplicate rule",
       %{conn: conn} do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Rivers",
        club_name: "West Coast Paddlers"
      )

    _alice =
      create_active_member(
        email: "alice@example.com",
        name: "Alice Adams",
        club_id: robin.club_id,
        club_name: "West Coast Paddlers"
      )

    grant_manage_members!(robin)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("robin@example.com", robin)
      |> live(~p"/members/invitations/new")

    view
    |> form("#member-club-invitation-form", invitation: %{email: " ALICE@example.com "})
    |> render_submit()

    assert has_element?(
             view,
             "#flash-error",
             "That email address is already an active member of this club."
           )

    assert is_nil(
             Membership.get_pending_club_member_invitation_by_email(
               robin.club_id,
               "alice@example.com"
             )
           )

    assert_no_email_sent()
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

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)

    Repo.get(Memba.Membership.Projections.Club, club_id) ||
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

    %{
      club_id: club_id,
      membership_id: membership.membership_id,
      person_id: person.person_id
    }
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

  defp active_membership(club_id, person_id) do
    MembershipProjection
    |> where([membership], membership.club_id == ^club_id)
    |> where([membership], membership.person_id == ^person_id)
    |> where([membership], membership.active == true)
    |> Repo.one()
  end

  defp member_permission?(club_id, person_id, permission) do
    Repo.exists?(
      from(member_permission in MemberPermission,
        where: member_permission.club_id == ^club_id,
        where: member_permission.person_id == ^person_id,
        where: member_permission.permission == ^permission
      )
    )
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

  defp delivered_invitation_path!(email_address) do
    assert_receive {:email, email}

    assert email.to == [{"", email_address}]
    assert email.subject == "You're invited to join West Coast Paddlers"

    [invitation_url] =
      Regex.run(~r{https?://[^\s]+/invitations/club-members/[^\s]+}, email.text_body)

    assert email.text_body =~ "This invitation link can be used once"
    assert email.html_body =~ invitation_url

    %URI{path: path} = URI.parse(invitation_url)
    assert path =~ ~r{^/invitations/club-members/.+}

    path
  end

  defp new_browser_conn do
    Phoenix.ConnTest.build_conn()
    |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
