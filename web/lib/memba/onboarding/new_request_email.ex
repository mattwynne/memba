defmodule Memba.Onboarding.NewRequestEmail do
  @moduledoc """
  Builds and delivers Memba-staff notifications for new onboarding requests.
  """

  import Swoosh.Email

  alias Memba.EmailTemplates
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
    to_address = to_address()

    new()
    |> from(from_address())
    |> to(to_address)
    |> reply_to({request.requester_name, request.requester_email})
    |> subject("New Memba request: #{request.requested_club_name}")
    |> text_body(body)
    |> html_body(render_html_body(body, recipient_email(to_address)))
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

    Open this request:
    #{staff_request_url(request)}
    """
  end

  defp staff_request_url(%Request{} = request) do
    MembaWeb.Endpoint.url() <> "/admin/requests/" <> request.request_id
  end

  defp render_html_body(text, recipient_email) do
    title = "New Memba access request"

    content = [
      EmailTemplates.memba_header(label: "Staff notification"),
      EmailTemplates.card_section([
        EmailTemplates.heading(title),
        EmailTemplates.plaintext_to_html(text, color: "#2c3a35")
      ])
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader: "New Memba access request for Memba staff.",
      content: content,
      footer:
        EmailTemplates.memba_footer(
          recipient_email: recipient_email,
          reason: "This staff notification was sent because someone requested access to Memba."
        )
    )
  end

  defp recipient_email({_name, address}) when is_binary(address), do: address
  defp recipient_email(address) when is_binary(address), do: address
  defp recipient_email(_address), do: ""

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:onboarding_new_request_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error,
       {:onboarding_new_request_email_delivery_error, {:unexpected_delivery_result, result}}}
end
