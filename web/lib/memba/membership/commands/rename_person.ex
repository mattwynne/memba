defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc """
  Command for a Person to conditionally change their own name.

  `expected_name` is the name from which the edit began. The Person aggregate
  compares it with its authoritative current name before recording a change.
  """

  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
