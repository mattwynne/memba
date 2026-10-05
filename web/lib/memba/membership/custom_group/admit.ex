defmodule Memba.Membership.CustomGroup.Admit do
  @moduledoc """
  Prepare admission of a club member to a custom group.

  Club decides actor authority, group identity, and target eligibility.
  """

  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.CustomGroup.Required

  def prepare(attrs) when is_map(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, group_id} <- Required.fetch(attrs, :group_id),
         {:ok, membership_id} <- Required.fetch(attrs, :membership_id),
         {:ok, person_id} <- Required.fetch(attrs, :person_id),
         {:ok, actor_person_id} <- Required.fetch(attrs, :actor_person_id) do
      {:ok,
       %AddCustomGroupMember{
         club_id: club_id,
         group_id: group_id,
         membership_id: membership_id,
         person_id: person_id,
         actor_person_id: actor_person_id
       }}
    end
  end
end
