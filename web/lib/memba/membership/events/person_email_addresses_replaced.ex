defmodule Memba.Membership.Events.PersonEmailAddressesReplaced do
  @moduledoc """
  Event raised when a person's full email-address set has been replaced.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :email_addresses, :primary_email]
  defstruct [:person_id, :email_addresses, :primary_email]
end
