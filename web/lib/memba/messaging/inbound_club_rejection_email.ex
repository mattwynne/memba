defmodule Memba.Messaging.InboundClubRejectionEmail do
  @moduledoc """
  Builds and delivers concise rejection emails for inbound club messages.

  Rejection emails use the application mailer and the configured messaging sender
  address so local/test/production mailer adapters stay switchable.
  """

  import Swoosh.Email

  alias Memba.Messaging.InboundEmail

  @subject "Your email was not posted"
  @fallback_from {"Memba", "messages@mail.memba.io"}

  @doc """
  Deliver a rejection email to the inbound sender.
  """
  def deliver(
        %InboundEmail{} = inbound_email,
        to_address,
        rejection_reason,
        delivery_reference
      )
      when is_binary(rejection_reason) and is_binary(delivery_reference) do
    inbound_email
    |> email(to_address, rejection_reason, delivery_reference)
    |> deliver_email()
  end

  defp email(
         %InboundEmail{} = inbound_email,
         to_address,
         rejection_reason,
         delivery_reference
       ) do
    reason = reason_copy(rejection_reason)
    body = text_body(reason)

    new()
    |> from(from_address())
    |> maybe_reply_to(reply_to_address())
    |> to(inbound_email.from_address)
    |> subject(@subject)
    |> text_body(body)
    |> html_body(html_body(body))
    |> put_provider_options(inbound_email, to_address, rejection_reason, delivery_reference)
  end

  defp from_address do
    configured_from_address() || @fallback_from
  end

  defp configured_from_address do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)

      Memba.Messaging.EmailDeliveryProviders.Postmark ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      Memba.Messaging.EmailDeliveryProviders.Local ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      _provider ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark) ||
          messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)
    end
  end

  defp messaging_provider_from_address(provider_module) do
    :memba
    |> Application.get_env(provider_module, [])
    |> Keyword.get(:from)
    |> normalize_address()
  end

  defp reply_to_address do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Resend)

      Memba.Messaging.EmailDeliveryProviders.Postmark ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      Memba.Messaging.EmailDeliveryProviders.Local ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      _provider ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark) ||
          messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Resend)
    end
  end

  defp messaging_provider_reply_to_address(provider_module) do
    :memba
    |> Application.get_env(provider_module, [])
    |> Keyword.get(:reply_to)
    |> normalize_address()
  end

  defp normalize_address({_name, address} = named_address) when is_binary(address) do
    named_address
  end

  defp normalize_address(address) when is_binary(address) do
    case String.trim(address) do
      "" -> nil
      address -> {"Memba", address}
    end
  end

  defp normalize_address(_address), do: nil

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, reply_to_address), do: reply_to(email, reply_to_address)

  defp put_provider_options(
         email,
         inbound_email,
         to_address,
         rejection_reason,
         delivery_reference
       ) do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        email
        |> put_provider_option(:tags, [
          %{name: "memba_email_kind", value: "inbound_club_rejection"},
          %{name: "memba_inbound_provider_message_id", value: inbound_email.provider_message_id},
          %{name: "memba_rejection_reason", value: rejection_reason},
          %{name: "memba_rejection_delivery_reference", value: delivery_reference}
        ])
        |> header("X-Memba-Inbound-Email-ID", InboundEmail.identity(inbound_email))
        |> header("X-Memba-Rejection-Delivery-Reference", delivery_reference)

      _provider ->
        put_provider_option(
          email,
          :metadata,
          metadata(inbound_email, to_address, rejection_reason, delivery_reference)
        )
    end
  end

  defp selected_provider do
    Application.get_env(:memba, :messaging_email_delivery_provider)
  end

  defp metadata(inbound_email, to_address, rejection_reason, delivery_reference) do
    %{
      "memba_email_kind" => "inbound_club_rejection",
      "memba_inbound_id" => InboundEmail.identity(inbound_email),
      "memba_in_provider" => inbound_email.provider,
      "memba_in_msg_id" => inbound_email.provider_message_id,
      "memba_in_to" => to_address,
      "memba_reject_reason" => rejection_reason,
      "memba_reject_ref" => delivery_reference
    }
    |> Map.new(fn {key, value} -> {key, postmark_metadata_value(value)} end)
  end

  defp postmark_metadata_value(value) do
    value
    |> to_string()
    |> String.slice(0, 80)
  end

  defp reason_copy("attachments_not_supported"), do: "attachments are not supported yet"
  defp reason_copy("plain_text_required"), do: "a plain text message body is required"

  defp reason_copy("unknown_sender"),
    do: "we could not find a member account for your sender address"

  defp reason_copy("sender_not_active_member"),
    do: "your sender address is not an active member of that club"

  defp reason_copy("unknown_club_slug"), do: "the club address was not recognized"
  defp reason_copy("unsupported_recipient_address"), do: "the recipient address is not supported"

  defp reason_copy(_reason), do: "the email could not be posted"

  defp text_body(reason) do
    """
    Your email was not posted: #{reason}.

    For help, reply to this email or contact Memba support.
    """
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
      {:error,
       {:inbound_club_rejection_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:inbound_club_rejection_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error,
       {:inbound_club_rejection_email_delivery_error, {:unexpected_delivery_result, result}}}
end
