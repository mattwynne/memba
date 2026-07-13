defmodule Memba.Membership.Events.PersonEmailAddressRemoved do
  @moduledoc """
  Event raised when a non-primary email address has been removed from a person.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :email, :normalized_email]
  defstruct [:person_id, :email, :normalized_email]
end
