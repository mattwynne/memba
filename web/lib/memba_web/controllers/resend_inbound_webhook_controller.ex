defmodule MembaWeb.ResendInboundWebhookController do
  use MembaWeb, :controller

  alias Memba.Messaging
  alias MembaWeb.ResendInboundEmailParser

  @successful_status :accepted

  def create(conn, params) do
    case verify_and_parse_resend_inbound_event(conn, params) do
      {:ok, attrs} ->
        accept_resend_inbound_email(conn, attrs)

      {:error, reason} ->
        render_error(conn, reason)
    end
  end

  defp accept_resend_inbound_email(conn, attrs) do
    case Messaging.receive_inbound_club_email(attrs, consistency: :strong) do
      {:ok, _result} ->
        conn
        |> put_status(@successful_status)
        |> json(%{status: "accepted"})

      {:error, reason} ->
        render_error(conn, reason)
    end
  end

  defp verify_and_parse_resend_inbound_event(conn, params) do
    with :ok <- verify_signature(conn) do
      ResendInboundEmailParser.parse(params)
    end
  end

  defp verify_signature(conn) do
    if MembaWeb.ResendWebhookSignature.configured?() do
      MembaWeb.ResendWebhookSignature.verify(conn)
    else
      :ok
    end
  end

  defp render_error(conn, reason) do
    conn
    |> put_status(error_status(reason))
    |> json(%{errors: %{detail: error_detail(reason)}})
  end

  defp error_status(:invalid_signature), do: :unauthorized
  defp error_status(:stale_timestamp), do: :unauthorized
  defp error_status(:invalid_timestamp), do: :unauthorized
  defp error_status(:missing_signing_secret), do: :unauthorized
  defp error_status(:missing_raw_body), do: :unauthorized
  defp error_status({:missing_header, _header}), do: :unauthorized
  defp error_status(_reason), do: :unprocessable_entity

  defp error_detail(:invalid_signature), do: "Invalid Resend webhook signature"
  defp error_detail(:stale_timestamp), do: "Stale Resend webhook timestamp"
  defp error_detail(:invalid_timestamp), do: "Invalid Resend webhook timestamp"
  defp error_detail(:missing_signing_secret), do: "Missing Resend webhook signing secret"
  defp error_detail(:missing_raw_body), do: "Missing raw Resend webhook body"

  defp error_detail({:missing_header, header}) do
    "Missing Resend webhook signature header: #{header}"
  end

  defp error_detail({:unsupported_event_type, nil}) do
    "Unsupported Resend inbound webhook event type"
  end

  defp error_detail({:unsupported_event_type, event_type}) do
    "Unsupported Resend inbound webhook event type: #{event_type}"
  end

  defp error_detail({:missing_required_attribute, attribute}) do
    "Missing required Resend inbound webhook attribute: #{attribute}"
  end

  defp error_detail(:invalid_from_address), do: "Invalid Resend inbound webhook from address"

  defp error_detail(:invalid_recipient_addresses) do
    "Invalid Resend inbound webhook recipient addresses"
  end

  defp error_detail(:invalid_provider_message_id) do
    "Invalid Resend inbound webhook provider message id"
  end

  defp error_detail(:invalid_attachments), do: "Invalid Resend inbound webhook attachments"
  defp error_detail(:invalid_html_body), do: "Invalid Resend inbound webhook HTML body"
  defp error_detail(:invalid_payload), do: "Invalid Resend inbound webhook payload"

  defp error_detail(reason) do
    "Could not process Resend inbound webhook: #{inspect(reason)}"
  end
end
