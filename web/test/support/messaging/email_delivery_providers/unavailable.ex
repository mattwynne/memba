defmodule Memba.Messaging.EmailDeliveryProviders.Unavailable do
  @moduledoc """
  Test email delivery provider that simulates the sending boundary being unavailable.
  """

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest

  @behaviour EmailDeliveryProvider

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{}), do: {:error, :unavailable}
end
