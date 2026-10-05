defmodule Memba.Membership.ProjectedIdentityLookup do
  @moduledoc """
  Typed invitation projection lookup used by the public Membership API and
  invitation-acceptance workflow. Person reads live in `PersonQueries`.
  """

  alias Memba.ID
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Repo

  def club_invitation(invitation_id) do
    with {:ok, invitation_id} <- ID.cast(:club_invitation, invitation_id) do
      Repo.get(ClubInvitation, invitation_id)
    else
      :error -> nil
    end
  end
end
