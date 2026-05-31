defmodule Memba.Messaging.DeliveryProviders.Postmark do
  @moduledoc """
  Postmark-backed delivery provider selected by explicit runtime configuration.

  Email construction and Swoosh delivery are implemented by later tasks in the
  Postmark integration iteration. Until then, selecting this provider fails
  visibly instead of silently falling back to fake delivery.
  """

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest

  @behaviour DeliveryProvider

  @impl DeliveryProvider
  def deliver(%DeliveryRequest{}) do
    {:error, :postmark_delivery_not_configured}
  end
end
