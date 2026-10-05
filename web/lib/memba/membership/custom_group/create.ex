defmodule Memba.Membership.CustomGroup.Create do
  @moduledoc """
  Prepare an actor-bearing custom-group creation request for the Club aggregate.

  The caller owns the stable group ID across retries. Preparation does not
  authorize or reserve a name; the aggregate makes that decision at dispatch.
  """

  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.CustomGroup.Required

  def prepare(attrs) when is_map(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, group_id} <- Required.fetch(attrs, :group_id),
         {:ok, actor_person_id} <- Required.fetch(attrs, :actor_person_id),
         {:ok, name} <- Required.fetch(attrs, :name) do
      {:ok,
       %CreateCustomGroup{
         club_id: club_id,
         group_id: group_id,
         actor_person_id: actor_person_id,
         name: name
       }}
    end
  end
end
