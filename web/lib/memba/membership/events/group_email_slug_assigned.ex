defmodule Memba.Membership.Events.GroupEmailSlugAssigned do
  @moduledoc """
  Event raised when a group has been assigned its stable inbound-email routing slug.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :email_slug]
  defstruct [:club_id, :group_id, :email_slug]
end
