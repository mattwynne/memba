defmodule Memba.Membership.Events.GroupEmailSlugAssigned do
  @moduledoc """
  Event raised when an immutable email routing slug has been assigned to a group.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :email_slug]
  defstruct [:club_id, :group_id, :email_slug]
end
