defmodule Memba.Membership.Commands.MakePersonEmailAddressPrimary do
  @moduledoc """
  Command to make a verified person email address primary.
  """

  @enforce_keys [:person_id, :email]
  defstruct [:person_id, :email]
end
