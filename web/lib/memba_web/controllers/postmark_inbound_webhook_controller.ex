defmodule MembaWeb.PostmarkInboundWebhookController do
  use MembaWeb, :controller

  alias Memba.Messaging
  alias MembaWeb.PostmarkInboundEmailParser

  @successful_status :accepted

  def create(conn, params) do
    case parse_and_handle_postmark_inbound_event(params) do
      :ok ->
        conn
        |> put_status(@successful_status)
        |> json(%{status: "accepted"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: error_detail(reason)}})
    end
  end

  defp parse_and_handle_postmark_inbound_event(params) do
    with {:ok, attrs} <- PostmarkInboundEmailParser.parse(params),
         {:ok, _result} <- Messaging.receive_inbound_club_email(attrs, consistency: :strong) do
      :ok
    end
  end

  defp error_detail({:missing_required_attribute, attribute}) do
    "Missing required Postmark inbound webhook attribute: #{attribute}"
  end

  defp error_detail(:invalid_from_address), do: "Invalid Postmark inbound webhook from address"

  defp error_detail(:invalid_recipient_addresses) do
    "Invalid Postmark inbound webhook recipient addresses"
  end

  defp error_detail(:invalid_provider_message_id) do
    "Invalid Postmark inbound webhook provider message id"
  end

  defp error_detail(:invalid_attachments), do: "Invalid Postmark inbound webhook attachments"
  defp error_detail(:invalid_html_body), do: "Invalid Postmark inbound webhook HTML body"
  defp error_detail(:invalid_payload), do: "Invalid Postmark inbound webhook payload"

  defp error_detail(reason) do
    "Could not process Postmark inbound webhook: #{inspect(reason)}"
  end
end
