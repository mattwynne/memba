defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc """
  Request a conditional rename of an existing Person.

  `expected_name` is the name observed when editing began.
  """

  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
