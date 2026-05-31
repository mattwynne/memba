defmodule Memba.Messaging.DeliveryProviders.Postmark do
  @moduledoc """
  Postmark-backed delivery provider selected by explicit runtime configuration.

  Email construction and Swoosh delivery are implemented by later tasks in the
  Postmark integration iteration. Until then, selecting this provider fails
  visibly instead of silently falling back to fake delivery.
  """

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.DeliveryProviders.PostmarkConfig

  @behaviour DeliveryProvider

  @impl DeliveryProvider
  def deliver(%DeliveryRequest{}) do
    case PostmarkConfig.from_application_env() do
      {:ok, %PostmarkConfig{}} ->
        {:error, :postmark_delivery_not_implemented}

      {:error, message} ->
        {:error, {:postmark_configuration_error, message}}
    end
  end
end
