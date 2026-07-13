defmodule Memba.Membership.Events.PersonEmailAddressAdded do
  @moduledoc """
  Event raised when a pending email address has been added to a person.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :email, :normalized_email]
  defstruct [:person_id, :email, :normalized_email]
end
