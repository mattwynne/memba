defmodule Memba.Membership.Commands.RemoveMember do
  @moduledoc """
  Command to remove a person from active club membership.

  The caller supplies the aggregate identity as `membership_id`.
  """

  @enforce_keys [:membership_id]
  defstruct [:membership_id]
end
