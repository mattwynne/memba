defmodule Memba.Messaging.DeliveryProviders.Postmark do
  @moduledoc """
  Postmark-backed delivery provider for outbound member broadcasts.

  It uses the application's Swoosh mailer so tests can keep using the test
  adapter while production uses Swoosh's Postmark adapter.
  """

  import Swoosh.Email

  alias Memba.Mailer
  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest

  @behaviour DeliveryProvider

  @impl DeliveryProvider
  def deliver(%DeliveryRequest{channel: :email} = request) do
    request
    |> email()
    |> Mailer.deliver()
    |> normalize_delivery_result()
  end

  def deliver(%DeliveryRequest{channel: channel}) do
    {:error, {:unsupported_channel, channel}}
  end

  defp email(%DeliveryRequest{} = request) do
    config = provider_config()

    new()
    |> from(config[:from])
    |> reply_to(config[:reply_to])
    |> to({request.recipient_name, request.recipient_address})
    |> subject(request.subject)
    |> text_body(request.body)
    |> put_provider_option(:message_stream, config[:message_stream])
    |> put_provider_option(:track_opens, config[:track_opens])
    |> put_provider_option(:track_links, config[:track_links])
    |> put_provider_option(:metadata, metadata(request))
  end

  defp metadata(%DeliveryRequest{} = request) do
    %{
      "memba_message_id" => request.message_id,
      "memba_delivery_id" => request.delivery_id,
      "memba_club_id" => request.club_id,
      "memba_recipient_id" => request.recipient_id
    }
  end

  defp provider_config do
    Application.get_env(:memba, __MODULE__, [])
  end

  defp normalize_delivery_result({:ok, _response}), do: :ok
  defp normalize_delivery_result(:ok), do: :ok
  defp normalize_delivery_result({:error, _reason} = error), do: error
end
