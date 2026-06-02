defmodule Memba.Membership.Commands.ReplacePersonEmailAddresses do
  @moduledoc """
  Command to atomically replace every email address attached to a person.
  """

  @enforce_keys [:person_id, :email_addresses]
  defstruct [:person_id, :email_addresses]
end
