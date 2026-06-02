defmodule Memba.Messaging.Events.EmailDeliveryOpened do
  @moduledoc """
  Legacy event kept for deserializing historic event-store data.

  Current Messaging behaviour does not emit opened delivery events.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
