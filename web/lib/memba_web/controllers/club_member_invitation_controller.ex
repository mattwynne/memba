defmodule MembaWeb.ClubMemberInvitationController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Membership
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Person
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @invalid_link_notice "That invitation link is no longer valid. Please ask for a new invitation."
  @profile_completion_path "/invitations/club-members/profile"

  def callback(conn, %{"token" => token}) do
    case Membership.get_club_member_invitation_by_token(token) do
      %ClubInvitation{status: "pending"} = invitation ->
        continue_pending_invitation(conn, invitation)

      %ClubInvitation{status: "accepted"} = invitation ->
        redirect_accepted_invitation(conn, invitation)

      _missing_or_invalid ->
        reject_invitation_link(conn, :not_found)
    end
  end

  defp continue_pending_invitation(conn, %ClubInvitation{} = invitation) do
    case Membership.get_person_by_email(invitation.normalized_email) do
      %Person{} = person ->
        accept_existing_person_invitation(conn, invitation, person)

      nil ->
        start_profile_completion(conn, invitation)
    end
  end

  defp accept_existing_person_invitation(
         conn,
         %ClubInvitation{} = invitation,
         %Person{} = person
       ) do
    case Membership.accept_club_member_invitation_for_existing_person(
           %{invitation_id: invitation.invitation_id, person_id: person.person_id},
           consistency: :strong
         ) do
      {:ok, _acceptance} ->
        conn
        |> IdentityAuth.log_in_identity(invitation.normalized_email)
        |> delete_session(IdentityAuth.club_member_invitation_session_key())
        |> put_flash(:info, "Invitation accepted.")
        |> redirect_to_invited_club(invitation)

      {:error, reason} ->
        reject_invitation_link(conn, reason)
    end
  end

  defp start_profile_completion(conn, %ClubInvitation{} = invitation) do
    conn
    |> IdentityAuth.log_in_identity(invitation.normalized_email)
    |> put_session(IdentityAuth.club_member_invitation_session_key(), %{
      "invitation_id" => invitation.invitation_id,
      "club_id" => invitation.club_id,
      "email" => invitation.normalized_email
    })
    |> put_flash(:info, profile_completion_notice(invitation))
    |> redirect(to: @profile_completion_path)
  end

  defp redirect_accepted_invitation(conn, %ClubInvitation{} = invitation) do
    conn
    |> IdentityAuth.log_in_identity(invitation.normalized_email)
    |> delete_session(IdentityAuth.club_member_invitation_session_key())
    |> redirect_to_invited_club(invitation)
  end

  defp redirect_to_invited_club(conn, %ClubInvitation{} = invitation) do
    case Membership.get_club(invitation.club_id) do
      nil ->
        redirect(conn, to: ~p"/")

      club ->
        redirect_to_club_url(conn, ClubSite.url(club, "/"))
    end
  end

  defp redirect_to_club_url(conn, "http" <> _rest = url), do: redirect(conn, external: url)
  defp redirect_to_club_url(conn, path), do: redirect(conn, to: path)

  defp profile_completion_notice(%ClubInvitation{} = invitation) do
    case Membership.get_club(invitation.club_id) do
      nil -> "Finish your profile to accept this invitation."
      club -> "Finish your profile to join #{club.name}."
    end
  end

  defp reject_invitation_link(conn, reason) do
    Logger.warning("Rejected club member invitation callback: #{inspect(reason)}")

    conn
    |> delete_session(IdentityAuth.club_member_invitation_session_key())
    |> put_flash(:error, @invalid_link_notice)
    |> redirect(to: ~p"/auth")
  end
end
