defmodule Memba.Membership.ProjectedIdentityLookup do
  @moduledoc """
  Typed lookups for the person and invitation projections used by the public
  Membership queries and invitation-acceptance workflow.
  """

  alias Memba.ID
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Person
  alias Memba.Repo

  def person(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      Repo.get(Person, person_id)
    else
      :error -> nil
    end
  end

  def club_invitation(invitation_id) do
    with {:ok, invitation_id} <- ID.cast(:club_invitation, invitation_id) do
      Repo.get(ClubInvitation, invitation_id)
    else
      :error -> nil
    end
  end
end
