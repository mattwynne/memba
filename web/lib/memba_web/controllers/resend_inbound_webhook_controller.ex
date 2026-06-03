defmodule MembaWeb.ResendInboundWebhookController do
  use MembaWeb, :controller

  alias MembaWeb.ResendInboundEmailParser

  @successful_status :accepted

  def create(conn, params) do
    case ResendInboundEmailParser.parse(params) do
      {:ok, _attrs} ->
        conn
        |> put_status(@successful_status)
        |> json(%{status: "accepted"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: error_detail(reason)}})
    end
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
