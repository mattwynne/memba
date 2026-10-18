defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc """
  Command to conditionally rename a person in the Membership context.
  """

  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
