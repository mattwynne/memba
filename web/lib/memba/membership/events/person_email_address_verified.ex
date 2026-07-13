defmodule Memba.Membership.Events.PersonEmailAddressVerified do
  @moduledoc """
  Event raised when a person's pending email address has been verified.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :email, :normalized_email, :verified_at]
  defstruct [:person_id, :email, :normalized_email, :verified_at]
end
