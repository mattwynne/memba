defmodule Memba.Messaging.EmailDeliveryProviders.Resend do
  @moduledoc """
  Resend-backed email delivery provider selected by explicit runtime configuration.

  The provider builds a multipart Swoosh email and hands it to `Memba.Mailer`.
  Recipient-specific delivery outcomes remain webhook-driven after Resend accepts
  the handoff.
  """

  import Swoosh.Email

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.EmailDeliveryProviders.ResendConfig

  @behaviour EmailDeliveryProvider

  @sender_name "Memba"

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{channel: :email} = request) do
    case ResendConfig.from_application_env() do
      {:ok, %ResendConfig{} = config} ->
        request
        |> email(config)
        |> deliver_email()

      {:error, message} ->
        {:error, {:resend_configuration_error, message}}
    end
  end

  def deliver(%EmailDeliveryRequest{channel: channel}),
    do: {:error, {:unsupported_delivery_channel, channel}}

  defp email(%EmailDeliveryRequest{} = request, %ResendConfig{} = config) do
    new()
    |> from({@sender_name, config.from})
    |> maybe_reply_to(config.reply_to)
    |> to({request.recipient_name, request.recipient_address})
    |> subject(request.subject)
    |> text_body(request.body)
    |> html_body(html_body(request.body))
    |> put_provider_option(:tags, tags(request))
    |> header("X-Memba-Message-ID", request.message_id)
    |> header("X-Memba-Delivery-ID", request.delivery_id)
    |> header("X-Memba-Club-ID", request.club_id)
  end

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, reply_to_address), do: reply_to(email, reply_to_address)

  defp tags(%EmailDeliveryRequest{} = request) do
    [
      %{name: "memba_message_id", value: request.message_id},
      %{name: "memba_delivery_id", value: request.delivery_id},
      %{name: "memba_club_id", value: request.club_id},
      %{name: "memba_email_kind", value: "member_message"}
    ]
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
      {:error, {:resend_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:resend_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:resend_delivery_error, {:unexpected_delivery_result, result}}}
end
