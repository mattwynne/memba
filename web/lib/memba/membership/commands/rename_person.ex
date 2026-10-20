defmodule Memba.Membership.Commands.RenamePerson do
  @moduledoc "Conditionally correct a Person's name against the edit's saved value."
  @enforce_keys [:person_id, :name, :expected_name]
  defstruct [:person_id, :name, :expected_name]
end
