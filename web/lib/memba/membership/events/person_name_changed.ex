defmodule Memba.Membership.Events.PersonNameChanged do
  @moduledoc """
  Event raised when a person changes their name.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :name]
  defstruct [:person_id, :name]
end
