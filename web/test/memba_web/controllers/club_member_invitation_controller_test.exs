defmodule MembaWeb.ClubMemberInvitationControllerTest do
  use MembaWeb.FeatureCase, async: false

  import Ecto.Query
  import Plug.Conn

  alias Memba.Membership
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  describe "GET /invitations/club-members/:token" do
    test "rejects unknown invitation tokens without signing in", %{conn: conn} do
      conn = get(conn, ~p"/invitations/club-members/not-a-real-token")

      assert redirected_to(conn) == ~p"/auth"

      assert flash(conn, :error) ==
               "That invitation link is no longer valid. Please ask for a new invitation."

      assert get_session(conn, IdentityAuth.identity_session_key()) == nil
      assert get_session(conn, IdentityAuth.club_member_invitation_session_key()) == nil
    end

    test "signs in an unknown invitee for profile completion without consuming the pending token",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      {invitation, token} = invite_member!(club, " ROBIN@Example.COM ")

      conn = get(conn, ~p"/invitations/club-members/#{token}")

      assert redirected_to(conn) == ~p"/invitations/club-members/profile"
      assert get_session(conn, IdentityAuth.identity_session_key()) == "robin@example.com"

      assert get_session(conn, IdentityAuth.club_member_invitation_session_key()) == %{
               "club_id" => club.club_id,
               "email" => "robin@example.com",
               "invitation_id" => invitation.invitation_id
             }

      assert %ClubInvitation{
               status: "pending",
               accepted_person_id: nil,
               accepted_membership_id: nil
             } = Membership.get_club_member_invitation(invitation.invitation_id)

      assert %ClubInvitation{status: "pending"} =
               Membership.get_club_member_invitation_by_token(token)

      refute Membership.get_person_by_email("robin@example.com")
      refute Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")
    end

    test "accepts a pending invitation for an existing person, signs in, and lands in the club",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")
      {invitation, token} = invite_member!(club, "ALICE@EXAMPLE.COM")

      conn = get(conn, ~p"/invitations/club-members/#{token}")

      assert redirected_to(conn) == ClubSite.url(club, "/")
      assert flash(conn, :info) == "Invitation accepted."
      assert get_session(conn, IdentityAuth.identity_session_key()) == "alice@example.com"
      assert get_session(conn, IdentityAuth.club_member_invitation_session_key()) == nil

      assert %ClubInvitation{
               status: "accepted",
               accepted_person_id: accepted_person_id,
               accepted_membership_id: accepted_membership_id
             } = Membership.get_club_member_invitation(invitation.invitation_id)

      assert accepted_person_id == person.person_id
      assert is_binary(accepted_membership_id)
      assert Membership.active_member_of_club_by_email?(club.club_id, "alice@example.com")
      assert membership_count(club.club_id, person.person_id) == 1
    end

    test "reopening an accepted invitation link signs in and does not create duplicate membership",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      person = insert_membership_person!(name: "Alice Example", email: "alice@example.com")
      {_invitation, token} = invite_member!(club, "alice@example.com")

      first_conn = get(conn, ~p"/invitations/club-members/#{token}")
      assert redirected_to(first_conn) == ClubSite.url(club, "/")
      assert membership_count(club.club_id, person.person_id) == 1

      second_conn =
        first_conn
        |> recycle()
        |> get(~p"/invitations/club-members/#{token}")

      assert redirected_to(second_conn) == ClubSite.url(club, "/")
      assert get_session(second_conn, IdentityAuth.identity_session_key()) == "alice@example.com"
      assert membership_count(club.club_id, person.person_id) == 1
    end
  end

  describe "GET /invitations/club-members/profile" do
    test "shows a profile-completion form for a verified unknown invitee without creating records",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      {invitation, token} = invite_member!(club, "robin@example.com")

      conn = get(conn, ~p"/invitations/club-members/#{token}")
      assert redirected_to(conn) == ~p"/invitations/club-members/profile"

      profile_conn = conn |> recycle() |> get(~p"/invitations/club-members/profile")
      response = html_response(profile_conn, 200)
      html = LazyHTML.from_fragment(response)

      assert response =~ "Tell us your name"
      assert response =~ "Kootenay Mountaineering Club"

      assert html
             |> LazyHTML.query("section#club-member-profile-completion")
             |> Enum.any?()

      assert html
             |> LazyHTML.query(
               "form#club-member-profile-completion-form[action='/invitations/club-members/profile']"
             )
             |> Enum.any?()

      assert html
             |> LazyHTML.query("input#club-member-profile-name-input[name='profile[name]']")
             |> Enum.any?()

      assert %ClubInvitation{status: "pending"} =
               Membership.get_club_member_invitation(invitation.invitation_id)

      refute Membership.get_person_by_email("robin@example.com")
      refute Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")
    end

    test "redirects browsers without a verified invitation journey", %{conn: conn} do
      conn = get(conn, ~p"/invitations/club-members/profile")

      assert redirected_to(conn) == ~p"/auth"

      assert flash(conn, :error) ==
               "Follow your invitation link before completing your profile."
    end
  end

  describe "POST /invitations/club-members/profile" do
    test "keeps a blank-name invitee on profile completion without accepting the invitation",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      {invitation, token} = invite_member!(club, "robin@example.com")

      conn = get(conn, ~p"/invitations/club-members/#{token}")

      profile_conn =
        conn
        |> recycle()
        |> post(~p"/invitations/club-members/profile", profile: %{name: " "})

      response = html_response(profile_conn, 422)

      assert response =~ "Tell us your name"
      assert response =~ "Please tell us your name."
      assert get_session(profile_conn, IdentityAuth.identity_session_key()) == "robin@example.com"

      assert get_session(profile_conn, IdentityAuth.club_member_invitation_session_key()) == %{
               "club_id" => club.club_id,
               "email" => "robin@example.com",
               "invitation_id" => invitation.invitation_id
             }

      assert %ClubInvitation{status: "pending"} =
               Membership.get_club_member_invitation(invitation.invitation_id)

      assert %ClubInvitation{status: "pending"} =
               Membership.get_club_member_invitation_by_token(token)

      refute Membership.get_person_by_email("robin@example.com")
      refute Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")
    end

    test "creates the invitee profile, activates ordinary membership, and clears journey state",
         %{conn: conn} do
      club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      {invitation, token} = invite_member!(club, "robin@example.com")

      conn = get(conn, ~p"/invitations/club-members/#{token}")

      profile_conn =
        conn
        |> recycle()
        |> post(~p"/invitations/club-members/profile", profile: %{name: " Robin Example "})

      assert redirected_to(profile_conn) == ClubSite.url(club, "/")
      assert flash(profile_conn, :info) == "Welcome to Kootenay Mountaineering Club."
      assert get_session(profile_conn, IdentityAuth.identity_session_key()) == "robin@example.com"
      assert get_session(profile_conn, IdentityAuth.club_member_invitation_session_key()) == nil

      assert %{person_id: person_id, name: "Robin Example", email: "robin@example.com"} =
               Membership.get_person_by_email("robin@example.com")

      assert %ClubInvitation{
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: accepted_membership_id
             } = Membership.get_club_member_invitation(invitation.invitation_id)

      assert is_binary(accepted_membership_id)
      assert Membership.active_member_of_club_by_email?(club.club_id, "robin@example.com")
      assert membership_count(club.club_id, person_id) == 1
    end
  end

  defp invite_member!(club, email) do
    assert {:ok, %{invitation_id: invitation_id, invitation_token: token}} =
             Membership.invite_club_member(
               %{club_id: club.club_id, email: email},
               consistency: :strong
             )

    {Membership.get_club_member_invitation(invitation_id), token}
  end

  defp membership_count(club_id, person_id) do
    MembershipProjection
    |> where([membership], membership.club_id == ^club_id)
    |> where([membership], membership.person_id == ^person_id)
    |> where([membership], membership.active == true)
    |> Repo.aggregate(:count)
  end

  defp flash(conn, key), do: Phoenix.Flash.get(conn.assigns.flash, key)
end
