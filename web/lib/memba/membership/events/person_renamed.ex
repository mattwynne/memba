defmodule Memba.Membership.Events.PersonRenamed do
  @moduledoc """
  Event raised when a person has changed their name.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :name]
  defstruct [:person_id, :name]
end
