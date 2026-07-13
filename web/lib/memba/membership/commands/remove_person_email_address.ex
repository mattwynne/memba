defmodule Memba.Membership.Commands.RemovePersonEmailAddress do
  @moduledoc """
  Command to remove a non-primary person email address.
  """

  @enforce_keys [:person_id, :email]
  defstruct [:person_id, :email]
end
