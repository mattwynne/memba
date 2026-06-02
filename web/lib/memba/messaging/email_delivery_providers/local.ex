defmodule Memba.Messaging.EmailDeliveryProviders.Local do
  @moduledoc """
  Local Swoosh-backed email delivery provider for browser acceptance and development tests.

  It hands the same member-message email shape to `Memba.Mailer` without requiring
  Postmark runtime configuration, so Swoosh's local mailbox can be inspected in a
  browser or through `/dev/mailbox/json`.
  """

  import Swoosh.Email

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest

  @behaviour EmailDeliveryProvider

  @default_from {"Memba", "messages@mail.memba.local"}

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{channel: :email} = request) do
    request
    |> email()
    |> deliver_email()
  end

  def deliver(%EmailDeliveryRequest{channel: channel}),
    do: {:error, {:unsupported_delivery_channel, channel}}

  defp email(%EmailDeliveryRequest{} = request) do
    new()
    |> from(from_address())
    |> maybe_reply_to(reply_to_address())
    |> to({request.recipient_name, request.recipient_address})
    |> subject(request.subject)
    |> text_body(request.body)
    |> html_body(html_body(request.body))
    |> put_provider_option(:metadata, metadata(request))
  end

  defp from_address do
    provider_config()
    |> Keyword.get(:from, @default_from)
  end

  defp reply_to_address do
    provider_config()
    |> Keyword.get(:reply_to)
  end

  defp provider_config do
    Application.get_env(:memba, Memba.Messaging.EmailDeliveryProviders.Postmark, [])
  end

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, reply_to_address), do: reply_to(email, reply_to_address)

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
      {:error, {:local_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:local_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:local_delivery_error, {:unexpected_delivery_result, result}}}
end
