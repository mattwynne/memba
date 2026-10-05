defmodule Memba.Membership.InvitationQueries do
  @moduledoc """
  Read-side lookups for projected club invitations. Tokens are never stored or
  compared in plaintext; accepted invitations remain retrievable by token for
  idempotent link reopening.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.ProjectedIdentityLookup
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Repo

  def get(invitation_id), do: ProjectedIdentityLookup.club_invitation(invitation_id)

  def get_pending_by_email(club_id, email) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, email} <- EmailAddresses.normalize_email(email) do
      ClubInvitation
      |> where([invitation], invitation.club_id == ^club_id)
      |> where([invitation], invitation.normalized_email == ^email.normalized_email)
      |> where([invitation], invitation.status == "pending")
      |> limit(1)
      |> Repo.one()
    else
      _invalid -> nil
    end
  end

  def get_by_token(token) when is_binary(token) do
    token
    |> InvitationToken.hash_token()
    |> then(&Repo.get_by(ClubInvitation, token_hash: &1))
  end

  def get_by_token(_token), do: nil
end
