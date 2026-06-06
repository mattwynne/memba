defmodule Memba.Onboarding.NewRequestEmail do
  @moduledoc """
  Builds and delivers Memba-staff notifications for new onboarding requests.
  """

  import Swoosh.Email

  alias Memba.Onboarding.Request

  @default_recipient "hello@memba.io"
  @default_from {"Memba", "hello@memba.io"}
  @default_message_stream "outbound-onboarding"

  @doc """
  Deliver a new-request notification email to Memba staff.
  """
  def deliver(%Request{} = request) do
    request
    |> email()
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  rescue
    exception ->
      {:error,
       {:onboarding_new_request_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  defp email(%Request{} = request) do
    body = text_body(request)

    new()
    |> from(from_address())
    |> to(to_address())
    |> reply_to({request.requester_name, request.requester_email})
    |> subject("New Memba request: #{request.requested_club_name}")
    |> text_body(body)
    |> html_body(html_body(body))
    |> put_provider_options(request)
  end

  defp from_address do
    config_value(:from) ||
      selected_provider_from_address() ||
      @default_from
  end

  defp to_address do
    config_value(:to) || @default_recipient
  end

  defp selected_provider_from_address do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)

      Memba.Messaging.EmailDeliveryProviders.Postmark ->
        provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      Memba.Messaging.EmailDeliveryProviders.Local ->
        provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      _provider ->
        provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark) ||
          provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)
    end
  end

  defp provider_from_address(provider_module) do
    :memba
    |> Application.get_env(provider_module, [])
    |> Keyword.get(:from)
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

  defp put_provider_options(email, %Request{} = request) do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        put_provider_option(email, :tags, [
          %{name: "memba_email_kind", value: "onboarding_new_request"},
          %{name: "memba_onboarding_request_id", value: request.request_id}
        ])

      _provider ->
        put_provider_option(email, :message_stream, message_stream())
    end
  end

  defp selected_provider do
    Application.get_env(:memba, :messaging_email_delivery_provider)
  end

  defp message_stream do
    config_value(:message_stream) || @default_message_stream
  end

  defp config_value(key) do
    :memba
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end

  defp text_body(%Request{} = request) do
    """
    New Memba access request

    Request ID: #{request.request_id}
    Club: #{request.requested_club_name}

    Requester:
    #{request.requester_name}
    #{request.requester_email}

    Note:
    #{request.note}
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

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:onboarding_new_request_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error,
       {:onboarding_new_request_email_delivery_error, {:unexpected_delivery_result, result}}}
end
