defmodule MembaWeb.ResendWebhookController do
  use MembaWeb, :controller

  alias Memba.Messaging

  @successful_status :accepted

  def create(conn, params) do
    case handle_resend_event(params) do
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

  defp handle_resend_event(params) do
    with {:ok, event_type} <- resend_event_type(params) do
      params
      |> status_report_attrs(event_type)
      |> report_status(event_type)
      |> normalize_dispatch_result()
    end
  end

  defp resend_event_type(params) do
    case normalize_token(event_value(params, [:type, "type", :event, "event"])) do
      "emaildelivered" -> {:ok, :delivered}
      "delivered" -> {:ok, :delivered}
      "emailopened" -> {:ok, :opened}
      "opened" -> {:ok, :opened}
      "emailbounced" -> {:ok, :bounced}
      "bounced" -> {:ok, :bounced}
      "emailcomplained" -> {:ok, :spam_complaint}
      "complained" -> {:ok, :spam_complaint}
      "emailspamcomplaint" -> {:ok, :spam_complaint}
      "spamcomplaint" -> {:ok, :spam_complaint}
      "emaildeliverydelayed" -> {:ok, :delayed}
      "deliverydelayed" -> {:ok, :delayed}
      "delayed" -> {:ok, :delayed}
      event_type -> {:error, {:unsupported_event_type, event_type}}
    end
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

  defp report_status(attrs, :delivered),
    do: Messaging.report_email_delivery_delivered(attrs)

  defp report_status(attrs, :delayed),
    do: Messaging.report_email_delivery_delayed(attrs)

  defp report_status(attrs, :bounced),
    do: Messaging.report_email_delivery_bounced(attrs)

  defp report_status(attrs, :spam_complaint),
    do: Messaging.report_email_delivery_spam_complaint(attrs)

  defp report_status(attrs, :opened),
    do: Messaging.report_email_delivery_opened(attrs)

  defp normalize_dispatch_result(:ok), do: :ok
  defp normalize_dispatch_result({:ok, _result}), do: :ok
  defp normalize_dispatch_result({:error, _reason} = error), do: error

  defp event_message_id(params) do
    params
    |> event_metadata()
    |> event_value([:message_id, "message_id", :memba_message_id, "memba_message_id"])
    |> present_or_else(fn ->
      event_value(params, [
        :message_id,
        "message_id",
        :memba_message_id,
        "memba_message_id",
        :"X-Memba-Message-ID",
        "X-Memba-Message-ID",
        :x_memba_message_id,
        "x_memba_message_id"
      ])
    end)
  end

  defp event_delivery_id(params) do
    params
    |> event_metadata()
    |> event_value([:delivery_id, "delivery_id", :memba_delivery_id, "memba_delivery_id"])
    |> present_or_else(fn ->
      event_value(params, [
        :delivery_id,
        "delivery_id",
        :memba_delivery_id,
        "memba_delivery_id",
        :"X-Memba-Delivery-ID",
        "X-Memba-Delivery-ID",
        :x_memba_delivery_id,
        "x_memba_delivery_id"
      ])
    end)
  end

  defp event_metadata(params) do
    data = event_data(params)

    %{}
    |> Map.merge(tags_metadata(event_value(data, [:tags, "tags"])))
    |> Map.merge(headers_metadata(event_value(data, [:headers, "headers"])))
    |> Map.merge(map_metadata(event_value(data, [:metadata, "metadata"])))
  end

  defp event_data(params) do
    case event_value(params, [:data, "data"]) do
      data when is_map(data) -> data
      _other -> params
    end
  end

  defp tags_metadata(tags) when is_list(tags) do
    Map.new(tags, fn
      %{"name" => name, "value" => value} -> {name, value}
      %{name: name, value: value} -> {name, value}
      {name, value} -> {name, value}
    end)
  end

  defp tags_metadata(_tags), do: %{}

  defp headers_metadata(headers) when is_list(headers) do
    Map.new(headers, fn
      %{"name" => name, "value" => value} -> {name, value}
      %{name: name, value: value} -> {name, value}
      {name, value} -> {name, value}
    end)
  end

  defp headers_metadata(headers) when is_map(headers), do: headers
  defp headers_metadata(_headers), do: %{}

  defp map_metadata(metadata) when is_map(metadata), do: metadata
  defp map_metadata(_metadata), do: %{}

  defp event_reason(params) do
    data = event_data(params)

    event_value(data, [
      :reason,
      "reason",
      :bounce,
      "bounce",
      :message,
      "message",
      :error,
      "error",
      :description,
      "description"
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

  defp normalize_token(nil), do: nil

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[\s_.-]+/, "")
  end

  defp error_detail({:unsupported_event_type, nil}) do
    "Unsupported Resend webhook event type"
  end

  defp error_detail({:unsupported_event_type, event_type}) do
    "Unsupported Resend webhook event type: #{event_type}"
  end

  defp error_detail({:missing_required_attribute, key}) do
    "Missing required Resend webhook attribute: #{key}"
  end

  defp error_detail(reason) do
    "Could not process Resend webhook: #{inspect(reason)}"
  end
end
