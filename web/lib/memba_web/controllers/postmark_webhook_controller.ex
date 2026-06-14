defmodule MembaWeb.PostmarkWebhookController do
  use MembaWeb, :controller

  require Logger

  alias Memba.Accounts
  alias Memba.Messaging

  @successful_status :accepted

  def create(conn, params) do
    case handle_postmark_event(params) do
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

  defp handle_postmark_event(params) do
    with {:ok, event_type} <- postmark_event_type(params) do
      params
      |> report_postmark_event(event_type)
      |> normalize_dispatch_result()
    end
  end

  defp postmark_event_type(params) do
    case normalize_token(
           event_value(params, [:RecordType, "RecordType", :record_type, "record_type"])
         ) do
      "delivery" -> {:ok, :delivered}
      "delivered" -> {:ok, :delivered}
      "delayed" -> {:ok, :delayed}
      "delay" -> {:ok, :delayed}
      "bounced" -> {:ok, :bounced}
      "spamcomplaint" -> {:ok, :spam_complaint}
      "spam" -> {:ok, :spam_complaint}
      "open" -> {:error, {:unsupported_record_type, "Open"}}
      "opened" -> {:error, {:unsupported_record_type, "Opened"}}
      "bounce" -> {:ok, bounce_event_type(params)}
      record_type -> {:error, {:unsupported_record_type, record_type}}
    end
  end

  defp bounce_event_type(params) do
    if delayed_bounce?(params), do: :delayed, else: :bounced
  end

  defp delayed_bounce?(params) do
    params
    |> event_value([:Type, "Type", :Name, "Name", :type, "type", :name, "name"])
    |> normalize_token()
    |> Kernel.in(["transient", "softbounce", "delayed", "deliverydelayed", "delay"])
  end

  defp status_report_attrs(params, event_type) do
    attrs = %{
      message_id: event_message_id(params),
      delivery_id: event_delivery_id(params)
    }

    if event_type in [:delayed, :bounced, :spam_complaint] do
      Map.put(attrs, :reason, event_reason(params))
    else
      attrs
    end
  end

  defp report_postmark_event(params, event_type) do
    if auth_email_event?(params) do
      report_auth_email_progress(params, event_type)
    else
      params
      |> status_report_attrs(event_type)
      |> report_status(event_type)
    end
  end

  defp report_status(attrs, :delivered),
    do: Messaging.report_email_delivery_delivered(attrs)

  defp report_status(attrs, :delayed),
    do: Messaging.report_email_delivery_delayed(attrs)

  defp report_status(attrs, :bounced),
    do: Messaging.report_email_delivery_bounced(attrs)

  defp report_status(attrs, :spam_complaint),
    do: Messaging.report_email_delivery_spam_complaint(attrs)

  defp report_auth_email_progress(params, event_type) do
    case event_auth_email_request_id(params) do
      nil ->
        Logger.info("Ignoring Postmark auth-email webhook without auth-email request correlation")
        :ok

      request_id ->
        params
        |> auth_email_progress_attrs(event_type)
        |> record_auth_email_progress(request_id, event_type)
        |> normalize_auth_email_progress_result(request_id)
    end
  end

  defp record_auth_email_progress(attrs, request_id, :delivered),
    do: Accounts.record_auth_email_provider_accepted(request_id, attrs)

  defp record_auth_email_progress(attrs, request_id, :delayed),
    do: Accounts.record_auth_email_provider_delayed(request_id, attrs)

  defp record_auth_email_progress(attrs, request_id, event_type)
       when event_type in [:bounced, :spam_complaint],
       do: Accounts.record_auth_email_provider_failed(request_id, attrs)

  defp normalize_auth_email_progress_result({:error, :not_found}, request_id) do
    Logger.info(
      "Ignoring Postmark auth-email webhook for unknown auth-email request #{inspect(request_id)}"
    )

    :ok
  end

  defp normalize_auth_email_progress_result(result, _request_id), do: result

  defp auth_email_event?(params) do
    auth_email_message_stream?(params) ||
      present_value(event_auth_email_request_id(params)) != nil
  end

  defp auth_email_message_stream?(params) do
    params
    |> event_message_stream()
    |> normalize_token()
    |> Kernel.==("outboundauthentication")
  end

  defp auth_email_progress_attrs(params, event_type) do
    attrs = %{
      provider: "postmark",
      provider_message_id: event_provider_message_id(params),
      provider_message_stream: event_message_stream(params),
      provider_event_id: event_provider_event_id(params),
      provider_event_type: event_record_type(params)
    }

    if event_type in [:delayed, :bounced, :spam_complaint] do
      Map.put(attrs, :provider_reason, event_reason(params))
    else
      attrs
    end
  end

  defp normalize_dispatch_result(:ok), do: :ok
  defp normalize_dispatch_result({:ok, _result}), do: :ok
  defp normalize_dispatch_result({:error, _reason} = error), do: error

  defp event_message_id(params) do
    params
    |> event_metadata()
    |> event_value([
      :message_id,
      "message_id",
      :memba_message_id,
      "memba_message_id",
      "MembaMessageID"
    ])
    |> present_or_else(fn ->
      event_value(params, [
        :message_id,
        "message_id",
        :memba_message_id,
        "memba_message_id",
        "MembaMessageID",
        "MessageID",
        :MessageID
      ])
    end)
  end

  defp event_delivery_id(params) do
    params
    |> event_metadata()
    |> event_value([
      :delivery_id,
      "delivery_id",
      :memba_delivery_id,
      "memba_delivery_id",
      "MembaDeliveryID"
    ])
    |> present_or_else(fn ->
      event_value(params, [
        :delivery_id,
        "delivery_id",
        :memba_delivery_id,
        "memba_delivery_id",
        "MembaDeliveryID",
        "DeliveryID",
        :DeliveryID
      ])
    end)
  end

  defp event_auth_email_request_id(params) do
    params
    |> event_metadata()
    |> event_value([
      :auth_email_request_id,
      "auth_email_request_id",
      :memba_auth_req_id,
      "memba_auth_req_id",
      :memba_auth_email_request_id,
      "memba_auth_email_request_id",
      "MembaAuthEmailRequestID"
    ])
    |> present_or_else(fn ->
      event_value(params, [
        :auth_email_request_id,
        "auth_email_request_id",
        :memba_auth_req_id,
        "memba_auth_req_id",
        :memba_auth_email_request_id,
        "memba_auth_email_request_id",
        "MembaAuthEmailRequestID"
      ])
    end)
  end

  defp event_provider_message_id(params) do
    event_value(params, [
      :MessageID,
      "MessageID",
      :message_id,
      "message_id",
      :MessageId,
      "MessageId"
    ])
  end

  defp event_message_stream(params) do
    event_value(params, [
      :MessageStream,
      "MessageStream",
      :message_stream,
      "message_stream"
    ])
  end

  defp event_provider_event_id(params) do
    params
    |> event_value([:ID, "ID", :id, "id", :MessageID, "MessageID"])
    |> present_to_string()
  end

  defp event_record_type(params) do
    params
    |> event_value([:RecordType, "RecordType", :record_type, "record_type"])
    |> present_to_string()
  end

  defp event_metadata(params) do
    case event_value(params, [:Metadata, "Metadata", :metadata, "metadata"]) do
      metadata when is_map(metadata) -> metadata
      _other -> %{}
    end
  end

  defp event_reason(params) do
    event_value(params, [
      :reason,
      "reason",
      :Details,
      "Details",
      :Description,
      "Description",
      :Message,
      "Message",
      :Name,
      "Name",
      :Type,
      "Type"
    ])
  end

  defp event_value(map, keys) when is_map(map) do
    Enum.find_value(keys, fn key ->
      map
      |> Map.get(key)
      |> present_value()
    end)
  end

  defp event_value(_map, _keys), do: nil

  defp present_or_else(value, fallback) when is_function(fallback, 0) do
    case present_value(value) do
      nil -> fallback.()
      present_value -> present_value
    end
  end

  defp present_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp present_value(nil), do: nil
  defp present_value(value), do: value

  defp present_to_string(nil), do: nil
  defp present_to_string(value), do: value |> to_string() |> present_value()

  defp normalize_token(nil), do: nil

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[\s_-]+/, "")
  end

  defp error_detail({:unsupported_record_type, nil}) do
    "Unsupported Postmark webhook RecordType"
  end

  defp error_detail({:unsupported_record_type, record_type}) do
    "Unsupported Postmark webhook RecordType: #{record_type}"
  end

  defp error_detail({:missing_required_attribute, key}) do
    "Missing required Postmark webhook attribute: #{key}"
  end

  defp error_detail(reason) do
    "Could not process Postmark webhook: #{inspect(reason)}"
  end
end
