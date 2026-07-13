defmodule Memba.Membership.Events.PersonPrimaryEmailAddressChanged do
  @moduledoc """
  Event raised when a person's verified primary email address has changed.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :primary_email, :normalized_email]
  defstruct [:person_id, :primary_email, :normalized_email]
end
