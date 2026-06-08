defmodule MembaWeb.ClubMemberInvitationController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Membership
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Person
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @invalid_link_notice "That invitation link is no longer valid. Please ask for a new invitation."
  @missing_profile_journey_notice "Follow your invitation link before completing your profile."
  @profile_completion_path "/invitations/club-members/profile"

  def profile(conn, _params) do
    case fetch_profile_journey(conn) do
      {:ok, journey} ->
        render_profile(conn, journey)

      {:accepted, %ClubInvitation{} = invitation} ->
        conn
        |> delete_session(IdentityAuth.club_member_invitation_session_key())
        |> redirect_to_invited_club(invitation)

      {:error, reason} ->
        reject_profile_journey(conn, reason)
    end
  end

  def complete_profile(conn, params) do
    case fetch_profile_journey(conn) do
      {:ok, journey} ->
        complete_pending_profile(conn, journey, profile_params(params))

      {:accepted, %ClubInvitation{} = invitation} ->
        conn
        |> delete_session(IdentityAuth.club_member_invitation_session_key())
        |> redirect_to_invited_club(invitation)

      {:error, reason} ->
        reject_profile_journey(conn, reason)
    end
  end

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

  defp complete_pending_profile(conn, journey, profile_params) do
    case Membership.complete_invited_club_member_profile(
           %{
             invitation_id: journey.invitation.invitation_id,
             name: Map.get(profile_params, "name")
           },
           consistency: :strong
         ) do
      {:ok, _acceptance} ->
        conn
        |> IdentityAuth.log_in_identity(journey.email)
        |> put_flash(:info, accepted_profile_message(journey))
        |> redirect_to_invited_club(journey.invitation)

      {:error, :invalid_name} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Please tell us your name.")
        |> render_profile(journey, profile_params, %{name: ["Please tell us your name."]})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, profile_completion_error(reason))
        |> render_profile(journey, profile_params)
    end
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

  defp render_profile(
         conn,
         journey,
         profile_params \\ %{"name" => ""},
         form_errors \\ %{name: []}
       ) do
    conn
    |> assign(:page_title, "Complete your profile")
    |> assign(:club, journey.club)
    |> assign(:email, journey.email)
    |> assign(:form_errors, form_errors)
    |> assign(:form, Phoenix.Component.to_form(profile_params(profile_params), as: :profile))
    |> render(:profile)
  end

  defp fetch_profile_journey(conn) do
    with %{"invitation_id" => invitation_id, "club_id" => club_id, "email" => email} <-
           get_session(conn, IdentityAuth.club_member_invitation_session_key()),
         current_email when is_binary(current_email) <-
           get_session(conn, IdentityAuth.identity_session_key()),
         :ok <- ensure_same_email(current_email, email),
         %ClubInvitation{} = invitation <- Membership.get_club_member_invitation(invitation_id),
         :ok <- ensure_matching_invitation(invitation, club_id, email) do
      case invitation.status do
        "pending" ->
          {:ok,
           %{
             invitation: invitation,
             club: Membership.get_club(invitation.club_id),
             email: invitation.normalized_email
           }}

        "accepted" ->
          {:accepted, invitation}

        _other_status ->
          {:error, :invalid_invitation_status}
      end
    else
      nil -> {:error, :missing_profile_journey}
      :error -> {:error, :missing_profile_journey}
      {:error, _reason} = error -> error
      _other -> {:error, :missing_profile_journey}
    end
  end

  defp ensure_same_email(email, email), do: :ok
  defp ensure_same_email(_current_email, _journey_email), do: {:error, :identity_email_mismatch}

  defp ensure_matching_invitation(%ClubInvitation{} = invitation, club_id, email) do
    if invitation.club_id == club_id and invitation.normalized_email == email do
      :ok
    else
      {:error, :invitation_session_mismatch}
    end
  end

  defp profile_params(%{"profile" => profile_params}) when is_map(profile_params) do
    %{"name" => Map.get(profile_params, "name", "")}
  end

  defp profile_params(%{"name" => _name} = profile_params) do
    %{"name" => Map.get(profile_params, "name", "")}
  end

  defp profile_params(_params), do: %{"name" => ""}

  defp accepted_profile_message(%{club: %{name: name}}) when is_binary(name) do
    "Welcome to #{name}."
  end

  defp accepted_profile_message(_journey), do: "Welcome to Memba."

  defp profile_completion_error(:email_address_taken),
    do: "That email address is already attached to another profile."

  defp profile_completion_error(:pending_invitation_not_found),
    do: @invalid_link_notice

  defp profile_completion_error(:already_accepted),
    do: @invalid_link_notice

  defp profile_completion_error(reason), do: "Could not complete your profile: #{inspect(reason)}"

  defp reject_profile_journey(conn, reason) do
    Logger.warning("Rejected club member invitation profile completion: #{inspect(reason)}")

    conn
    |> delete_session(IdentityAuth.club_member_invitation_session_key())
    |> put_flash(:error, @missing_profile_journey_notice)
    |> redirect(to: ~p"/auth")
  end

  defp reject_invitation_link(conn, reason) do
    Logger.warning("Rejected club member invitation callback: #{inspect(reason)}")

    conn
    |> delete_session(IdentityAuth.club_member_invitation_session_key())
    |> put_flash(:error, @invalid_link_notice)
    |> redirect(to: ~p"/auth")
  end
end
