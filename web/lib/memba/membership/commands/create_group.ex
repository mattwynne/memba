defmodule Memba.Membership.Commands.CreateGroup do
  @moduledoc """
  Command to create a club-scoped conversation group.

  The caller supplies the club aggregate identity as `club_id` and the group
  identity as `group_id`.
  """

  @enforce_keys [:club_id, :group_id, :name]
  defstruct [:club_id, :group_id, :group_key, :name]
end
