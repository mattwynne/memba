defmodule Memba.Messaging.DeliveryProvider do
  @moduledoc """
  Port for handing recipient deliveries to a delivery provider.

  The configured provider is intentionally small for this skeleton. A successful
  call means Memba has handed one recipient delivery to the provider.
  """

  alias Memba.Messaging.DeliveryRequest

  @callback deliver(DeliveryRequest.t()) :: :ok | {:error, term()}

  @doc """
  Hand one recipient delivery request to the configured provider.
  """
  def deliver(%DeliveryRequest{} = request) do
    provider().deliver(request)
  end

  defp provider do
    Application.get_env(:memba, :messaging_delivery_provider, Memba.Messaging.DeliveryProviders.Fake)
  end
end
