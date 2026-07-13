defmodule Memba.Membership.Commands.AddPersonEmailAddress do
  @moduledoc """
  Command to add a pending email address to a person.
  """

  @enforce_keys [:person_id, :email]
  defstruct [:person_id, :email]
end
