defmodule Memba.Membership.InvitationIssuance do
  @moduledoc """
  Prepare invitation issue and resend commands without dispatch or delivery.

  The projected active-member and pending-invitation checks provide the existing
  early feedback and repeat-invite behavior. The invitation aggregate still
  validates the state of its own stream at dispatch time.
  """

  alias Memba.ID
  alias Memba.Membership.Commands.{InviteClubMember, ResendClubMemberInvitation}
  alias Memba.Membership.InvitationQueries
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.MembershipQueries
  alias Memba.Membership.Projections.ClubInvitation

  def prepare_invite(attrs) when is_map(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, invitation_id} <- invitation_id(attrs),
         :ok <- prevent_inviting_active_member(club_id, email) do
      case InvitationQueries.get_pending_by_email(club_id, email) do
        %ClubInvitation{} = invitation ->
          prepare_resend_invitation(invitation)

        nil ->
          {token, hash} = new_token()

          {:ok,
           %InviteClubMember{
             invitation_id: invitation_id,
             club_id: club_id,
             email: email,
             token_hash: hash
           }, token}
      end
    end
  end

  def prepare_resend(attrs) when is_map(attrs) do
    with {:ok, invitation} <- pending_invitation_for_resend(attrs) do
      prepare_resend_invitation(invitation)
    end
  end

  defp prepare_resend_invitation(%ClubInvitation{} = invitation) do
    {token, hash} = new_token()

    {:ok, %ResendClubMemberInvitation{invitation_id: invitation.invitation_id, token_hash: hash},
     token}
  end

  defp new_token do
    token = InvitationToken.generate_token()
    {token, InvitationToken.hash_token(token)}
  end

  defp prevent_inviting_active_member(club_id, email) do
    if MembershipQueries.active_member_of_club_by_email?(club_id, email),
      do: {:error, :already_active_member},
      else: :ok
  end

  defp pending_invitation_for_resend(attrs) do
    case fetch_optional(attrs, :invitation_id) do
      {:ok, invitation_id} ->
        invitation_id
        |> InvitationQueries.get()
        |> ensure_pending_invitation()

      :error ->
        with {:ok, club_id} <- fetch_required(attrs, :club_id),
             {:ok, email} <- fetch_required(attrs, :email) do
          club_id
          |> InvitationQueries.get_pending_by_email(email)
          |> ensure_pending_invitation()
        end
    end
  end

  defp ensure_pending_invitation(nil), do: {:error, :pending_invitation_not_found}

  defp ensure_pending_invitation(%ClubInvitation{status: "pending"} = invitation),
    do: {:ok, invitation}

  defp ensure_pending_invitation(%ClubInvitation{status: "accepted"}),
    do: {:error, :already_accepted}

  defp invitation_id(attrs) do
    case fetch_optional(attrs, :invitation_id) do
      {:ok, invitation_id} -> {:ok, invitation_id}
      :error -> {:ok, ID.generate(:club_invitation)}
    end
  end

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
  end
end
