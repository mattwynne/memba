defmodule Memba.Membership.Events.GroupCreated do
  @moduledoc """
  Event raised when a club-scoped conversation group has been created.

  Its historical shape is retained for replay compatibility. Email identity and
  creator membership remain separate `GroupEmailSlugAssigned` and
  `GroupMemberAdded` facts.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :name]
  defstruct [:club_id, :group_id, :group_key, :name]
end
