defmodule Memba.Membership.Commands.AssignGroupEmailSlug do
  @moduledoc """
  Internal command to assign an immutable email routing slug to a group.
  """

  @enforce_keys [:club_id, :group_id, :email_slug]
  defstruct [:club_id, :group_id, :email_slug]
end
