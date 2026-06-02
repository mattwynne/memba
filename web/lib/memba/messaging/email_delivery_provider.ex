defmodule Memba.Messaging.EmailDeliveryProvider do
  @moduledoc """
  Port for handing email deliveries to a email delivery provider.

  The configured provider is intentionally small for this skeleton. A successful
  call means Memba has handed one email delivery to the provider.
  """

  alias Memba.Messaging.EmailDeliveryRequest

  @callback deliver(EmailDeliveryRequest.t()) :: :ok | {:error, term()}

  @doc """
  Hand one email delivery request to the configured provider.
  """
  def deliver(%EmailDeliveryRequest{} = request) do
    provider().deliver(request)
  end

  defp provider do
    Application.get_env(
      :memba,
      :messaging_email_delivery_provider,
      Memba.Messaging.EmailDeliveryProviders.Fake
    )
  end
end
