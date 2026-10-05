defmodule Memba.Membership.AddMember do
  @moduledoc """
  Prepare an active club membership command without dispatching it.

  The caller supplies a stable membership ID for retries. The Club aggregate
  decides first-member authority, idempotency, and duplicate active membership.
  """

  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.CustomGroup.Required

  def prepare(attrs) when is_map(attrs) do
    with {:ok, membership_id} <- Required.fetch(attrs, :membership_id),
         {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, person_id} <- Required.fetch(attrs, :person_id) do
      {:ok, %AddClubMember{membership_id: membership_id, club_id: club_id, person_id: person_id}}
    end
  end
end
