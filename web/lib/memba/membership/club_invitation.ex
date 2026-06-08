defmodule Memba.Membership.ClubInvitation do
  @moduledoc """
  Club member invitation aggregate for the Membership bounded context.

  The aggregate tracks the invitation lifecycle only: pending invitation, resend
  token rotation, and accepted state. Public application services orchestrate
  duplicate checks, email delivery, person creation, and membership creation.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.InvitationToken

  @behaviour Aggregate

  defstruct [
    :invitation_id,
    :club_id,
    :email,
    :normalized_email,
    :token_hash,
    :accepted_person_id,
    :accepted_membership_id,
    status: :new,
    resend_count: 0
  ]

  @impl Aggregate
  def execute(%__MODULE__{status: :new}, %InviteClubMember{} = command) do
    with :ok <- validate_id(:club_invitation, command.invitation_id, :invalid_invitation_id),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         {:ok, email} <- EmailAddresses.normalize_email(command.email),
         :ok <- validate_token_hash(command.token_hash) do
      %ClubMemberInvited{
        invitation_id: command.invitation_id,
        club_id: command.club_id,
        email: email.email,
        normalized_email: email.normalized_email,
        token_hash: command.token_hash
      }
    end
  end

  def execute(%__MODULE__{status: :pending}, %InviteClubMember{}),
    do: {:error, :already_pending}

  def execute(%__MODULE__{status: :accepted}, %InviteClubMember{}),
    do: {:error, :already_accepted}

  @impl Aggregate
  def execute(%__MODULE__{status: :new}, %ResendClubMemberInvitation{}),
    do: {:error, :not_found}

  def execute(%__MODULE__{status: :accepted}, %ResendClubMemberInvitation{}),
    do: {:error, :already_accepted}

  def execute(%__MODULE__{status: :pending} = invitation, %ResendClubMemberInvitation{} = command) do
    with :ok <- validate_same_invitation(invitation.invitation_id, command.invitation_id),
         :ok <- validate_token_hash(command.token_hash) do
      %ClubMemberInvitationResent{
        invitation_id: command.invitation_id,
        token_hash: command.token_hash
      }
    end
  end

  @impl Aggregate
  def execute(%__MODULE__{status: :new}, %AcceptClubMemberInvitation{}),
    do: {:error, :not_found}

  def execute(%__MODULE__{status: :accepted}, %AcceptClubMemberInvitation{}),
    do: {:error, :already_accepted}

  def execute(%__MODULE__{status: :pending} = invitation, %AcceptClubMemberInvitation{} = command) do
    with :ok <- validate_same_invitation(invitation.invitation_id, command.invitation_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id) do
      %ClubMemberInvitationAccepted{
        invitation_id: command.invitation_id,
        person_id: command.person_id,
        membership_id: command.membership_id
      }
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = invitation, %ClubMemberInvited{} = event) do
    %__MODULE__{
      invitation
      | invitation_id: event.invitation_id,
        club_id: event.club_id,
        email: event.email,
        normalized_email: event.normalized_email,
        token_hash: event.token_hash,
        status: :pending,
        resend_count: 0
    }
  end

  def apply(%__MODULE__{} = invitation, %ClubMemberInvitationResent{} = event) do
    %__MODULE__{
      invitation
      | token_hash: event.token_hash,
        resend_count: invitation.resend_count + 1
    }
  end

  def apply(%__MODULE__{} = invitation, %ClubMemberInvitationAccepted{} = event) do
    %__MODULE__{
      invitation
      | accepted_person_id: event.person_id,
        accepted_membership_id: event.membership_id,
        status: :accepted
    }
  end

  defp validate_same_invitation(invitation_id, invitation_id), do: :ok

  defp validate_same_invitation(_invitation_id, _command_invitation_id),
    do: {:error, :invitation_id_mismatch}

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end

  defp validate_token_hash(token_hash) do
    if InvitationToken.valid_hash?(token_hash) do
      :ok
    else
      {:error, :invalid_token_hash}
    end
  end
end
