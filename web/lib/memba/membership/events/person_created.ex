defmodule Memba.Membership.Events.PersonCreated do
  @moduledoc """
  Event raised when a person has been created.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :name, :email]
  defstruct [:person_id, :name, :email]
end
