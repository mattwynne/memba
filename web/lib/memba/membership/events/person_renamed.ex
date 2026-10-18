defmodule Memba.Membership.Events.PersonRenamed do
  @moduledoc """
  Event raised when a person's name has changed.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :name]
  defstruct [:person_id, :name]
end
