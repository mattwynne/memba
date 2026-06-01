defmodule Memba.Messaging.DeliveryProviders.Unavailable do
  @moduledoc """
  Test delivery provider that simulates the sending boundary being unavailable.
  """

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest

  @behaviour DeliveryProvider

  @impl DeliveryProvider
  def deliver(%DeliveryRequest{}), do: {:error, :unavailable}
end
