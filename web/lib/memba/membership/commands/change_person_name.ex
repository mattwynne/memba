defmodule Memba.Membership.Commands.ChangePersonName do
  @moduledoc """
  Command for a person to replace their own name when the expected name is
  still current.
  """

  @enforce_keys [:person_id, :actor_person_id, :expected_name, :name]
  defstruct [:person_id, :actor_person_id, :expected_name, :name]
end
