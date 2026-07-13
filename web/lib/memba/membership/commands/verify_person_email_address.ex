defmodule Memba.Membership.Commands.VerifyPersonEmailAddress do
  @moduledoc """
  Command to mark a pending person email address as verified.
  """

  @enforce_keys [:person_id, :email, :verified_at]
  defstruct [:person_id, :email, :verified_at]
end
