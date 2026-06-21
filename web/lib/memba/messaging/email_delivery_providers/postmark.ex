defmodule Memba.Messaging.EmailDeliveryProviders.Postmark do
  @moduledoc """
  Postmark-backed email delivery provider selected by explicit runtime configuration.

  The provider builds a multipart Swoosh email and hands it to `Memba.Mailer`.
  Recipient-specific delivery outcomes remain webhook-driven after Postmark
  accepts the handoff.
  """

  import Swoosh.Email

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.EmailDeliveryProviders.PostmarkConfig
  alias Memba.Messaging.MemberMessageEmail

  @behaviour EmailDeliveryProvider

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{channel: :email} = request) do
    case PostmarkConfig.from_application_env() do
      {:ok, %PostmarkConfig{} = config} ->
        request
        |> email(config)
        |> deliver_email()

      {:error, message} ->
        {:error, {:postmark_configuration_error, message}}
    end
  end

  def deliver(%EmailDeliveryRequest{channel: channel}),
    do: {:error, {:unsupported_delivery_channel, channel}}

  defp email(%EmailDeliveryRequest{} = request, %PostmarkConfig{} = config) do
    new()
    |> from({MemberMessageEmail.from_display_name(request), config.from})
    |> reply_to(MemberMessageEmail.reply_to(request))
    |> to(MemberMessageEmail.to(request))
    |> header("Message-ID", MemberMessageEmail.message_id(request))
    |> subject(MemberMessageEmail.subject(request))
    |> text_body(MemberMessageEmail.text_body(request))
    |> html_body(MemberMessageEmail.html_body(request))
    |> put_provider_option(:metadata, metadata(request))
  end

  defp metadata(%EmailDeliveryRequest{} = request) do
    %{
      "memba_message_id" => request.message_id,
      "memba_delivery_id" => request.delivery_id,
      "memba_club_id" => request.club_id
    }
  end

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  rescue
    exception ->
      {:error, {:postmark_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:postmark_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:postmark_delivery_error, {:unexpected_delivery_result, result}}}
end
