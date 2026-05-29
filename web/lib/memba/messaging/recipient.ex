defmodule Memba.Messaging.Recipient do
  @moduledoc """
  Resolved recipient carried by `SendMessage`.

  Recipients are resolved by the Messaging application service before command
  dispatch. The delivery identity is caller-supplied so the aggregate does not
  generate IDs.
  """

  @enforce_keys [:delivery_id, :person_id, :name, :email]
  defstruct [:delivery_id, :person_id, :name, :email]
end
