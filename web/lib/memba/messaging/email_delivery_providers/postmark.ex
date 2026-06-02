defmodule Memba.Messaging.EmailDeliveryProviders.Postmark do
  @moduledoc """
  Postmark-backed email delivery provider selected by explicit runtime configuration.

  The provider builds a multipart Swoosh email and hands it to `Memba.Mailer`.
  Recipient-specific delivery outcomes remain webhook-driven after Postmark
  accepts the handoff.
  """

  import Swoosh.Email

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.EmailDeliveryProviders.PostmarkConfig

  @behaviour EmailDeliveryProvider

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{channel: :email} = request) do
    case PostmarkConfig.from_application_env() do
      {:ok, %PostmarkConfig{} = config} ->
        request
        |> email(config)
        |> deliver_email()

      {:error, message} ->
        {:error, {:postmark_configuration_error, message}}
    end
  end

  def deliver(%EmailDeliveryRequest{channel: channel}),
    do: {:error, {:unsupported_delivery_channel, channel}}

  defp email(%EmailDeliveryRequest{} = request, %PostmarkConfig{} = config) do
    new()
    |> from({sender_display_name(request), config.from})
    |> reply_to({request.sender_name, request.sender_address})
    |> to({request.recipient_name, request.recipient_address})
    |> subject(request.subject)
    |> text_body(request.body)
    |> html_body(html_body(request.body))
    |> put_provider_option(:metadata, metadata(request))
    |> put_provider_option(:track_opens, true)
  end

  defp sender_display_name(%EmailDeliveryRequest{} = request) do
    "#{request.sender_name} via Memba"
  end

  defp metadata(%EmailDeliveryRequest{} = request) do
    %{
      "memba_message_id" => request.message_id,
      "memba_delivery_id" => request.delivery_id,
      "memba_club_id" => request.club_id
    }
  end

  defp html_body(text) do
    escaped_body =
      text
      |> String.split(~r/\r\n|\n|\r/, trim: false)
      |> Enum.map(&html_escape_to_string/1)
      |> Enum.join("<br>\n")

    "<html><body><p>#{escaped_body}</p></body></html>"
  end

  defp html_escape_to_string(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  rescue
    exception ->
      {:error, {:postmark_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:postmark_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:postmark_delivery_error, {:unexpected_delivery_result, result}}}
end
