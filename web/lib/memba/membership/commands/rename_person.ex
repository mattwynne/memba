defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc """
  Command to conditionally change a person's name.

  `expected_name` is the name from which the edit began.
  """

  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
