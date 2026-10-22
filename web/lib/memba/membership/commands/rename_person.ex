defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc """
  Command to rename a person when their current name still matches the supplied
  baseline.
  """

  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
