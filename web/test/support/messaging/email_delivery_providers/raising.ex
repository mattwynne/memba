defmodule Memba.Messaging.EmailDeliveryProviders.Raising do
  @moduledoc """
  Test email delivery provider that raises at the provider boundary.
  """

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest

  @behaviour EmailDeliveryProvider

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{}) do
    raise "provider exploded"
  end
end
