defmodule Memba.Membership.Commands.CreateCustomGroup do
  @moduledoc """
  Command for a club member actor to create a custom conversation group.

  The command is routed to the Club aggregate by `club_id`, where actor
  authority and club-scoped creation rules are decided from authoritative
  aggregate state. `group_id` is generated once per creation request and reused
  for retries so the aggregate can distinguish an exact retry from another
  creation.
  """

  @enforce_keys [:club_id, :group_id, :actor_person_id, :name]
  defstruct [:club_id, :group_id, :actor_person_id, :name]
end
