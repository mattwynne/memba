defmodule MembaWeb.ClubMemberInvitationsLive.SendTest do
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

  test "Membership Admin invitation form asks for email only", %{conn: conn} do
    robin =
      create_active_member(
        email: "robin-email-only@example.com",
        name: "Robin Admin",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members_permission(robin)

    {:ok, view, _html} =
      conn
      |> init_test_session(%{
        IdentityAuth.identity_session_key() => "robin-email-only@example.com"
      })
      |> live(~p"/members/invitations/new?club_id=#{robin.club_id}")

    assert has_element?(view, "#member-club-member-invitation-form[aria-label='Invite member']")

    assert has_element?(
             view,
             "#member-club-member-invitation-form input[name='invitation[email]'][type='email']"
           )

    refute has_element?(
             view,
             "#member-club-member-invitation-form input[name^='invitation[']:not([name='invitation[email]'])"
           )

    refute has_element?(
             view,
             "#member-club-member-invitation-form textarea[name^='invitation[']"
           )

    refute has_element?(
             view,
             "#member-club-member-invitation-form select[name^='invitation[']"
           )
  end

  test "Membership Admin submits an invitation through the shared club invitation lifecycle", %{
    conn: conn
  } do
    robin =
      create_active_member(
        email: "robin@example.com",
        name: "Robin Admin",
        club_name: "West Coast Paddlers"
      )

    grant_manage_members_permission(robin)

    {:ok, view, _html} =
      conn
      |> init_test_session(%{IdentityAuth.identity_session_key() => "robin@example.com"})
      |> live(~p"/members/invitations/new?club_id=#{robin.club_id}")

    view
    |> form("#member-club-member-invitation-form", invitation: %{email: " DANA@Example.COM "})
    |> render_submit()

    assert has_element?(view, "#flash-info", "Invitation sent to dana@example.com")

    assert %ClubInvitation{
             invitation_id: invitation_id,
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

    assert_email_sent(fn email ->
      assert email.to == [{"", "dana@example.com"}]
      assert email.subject == "You're invited to join West Coast Paddlers"
      assert email.text_body =~ "This invitation link can be used once"

      [invitation_url] =
        Regex.run(~r{https?://[^\s]+/invitations/club-members/[^\s]+}, email.text_body)

      %URI{path: "/invitations/club-members/" <> invitation_token} = URI.parse(invitation_url)

      assert %ClubInvitation{invitation_id: ^invitation_id, status: "pending"} =
               Membership.get_club_member_invitation_by_token(invitation_token)
    end)
  end

  defp create_active_member(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    person_id = Memba.ID.generate(:person)

    club =
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

    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    %{
      club_id: club_id,
      club: club,
      person_id: person.person_id,
      membership_id: membership_id
    }
  end

  defp grant_manage_members_permission(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp club_attrs(attrs, club_id) do
    base = [
      club_id: club_id,
      name: Keyword.get(attrs, :club_name, "West Coast Paddlers")
    ]

    case Keyword.fetch(attrs, :slug) do
      {:ok, slug} -> Keyword.put(base, :slug, slug)
      :error -> base
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
