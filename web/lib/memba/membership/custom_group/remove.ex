defmodule Memba.Membership.CustomGroup.Remove do
  @moduledoc """
  Prepare removal of a custom-group participant.

  The caller must retain the removal operation ID across uncertain retries;
  Club enforces authority and exact-retry identity at dispatch.
  """

  alias Memba.Membership.Commands.RemoveCustomGroupMember
  alias Memba.Membership.CustomGroup.Required

  def prepare(attrs) when is_map(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, group_id} <- Required.fetch(attrs, :group_id),
         {:ok, membership_id} <- Required.fetch(attrs, :membership_id),
         {:ok, person_id} <- Required.fetch(attrs, :person_id),
         {:ok, actor_person_id} <- Required.fetch(attrs, :actor_person_id),
         {:ok, removal_operation_id} <- Required.fetch(attrs, :removal_operation_id) do
      {:ok,
       %RemoveCustomGroupMember{
         club_id: club_id,
         group_id: group_id,
         membership_id: membership_id,
         person_id: person_id,
         actor_person_id: actor_person_id,
         removal_operation_id: removal_operation_id
       }}
    end
  end
end
