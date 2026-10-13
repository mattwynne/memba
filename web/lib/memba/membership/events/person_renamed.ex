defmodule Memba.Membership.Events.PersonRenamed do
  @moduledoc "The Person's current name has been corrected."
  @derive Jason.Encoder
  @enforce_keys [:person_id, :name]
  defstruct [:person_id, :name]
end
