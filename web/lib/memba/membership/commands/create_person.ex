defmodule Memba.Membership.Commands.CreatePerson do
  @moduledoc """
  Command to create a person in the Membership context.

  The caller supplies the aggregate identity as `person_id`.
  """

  @enforce_keys [:person_id, :name, :email]
  defstruct [:person_id, :name, :email]
end
