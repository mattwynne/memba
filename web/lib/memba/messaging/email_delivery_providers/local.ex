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
  alias Memba.Messaging.LocalDeliveryFacts
  alias Memba.Messaging.MemberMessageEmail

  @behaviour EmailDeliveryProvider

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{channel: :email} = request) do
    request
    |> email()
    |> deliver_email()
    |> record_delivery_fact(request)
  end

  def deliver(%EmailDeliveryRequest{channel: channel}),
    do: {:error, {:unsupported_delivery_channel, channel}}

  defp email(%EmailDeliveryRequest{} = request) do
    new()
    |> from({MemberMessageEmail.from_display_name(request), from_address()})
    |> reply_to(MemberMessageEmail.reply_to(request))
    |> to(MemberMessageEmail.to(request))
    |> header("Message-ID", MemberMessageEmail.message_id(request))
    |> subject(MemberMessageEmail.subject(request))
    |> text_body(MemberMessageEmail.text_body(request))
    |> html_body(MemberMessageEmail.html_body(request))
    |> put_provider_option(:metadata, metadata(request))
  end

  defp from_address do
    provider_config()
    |> Keyword.get(:from, "messages@mail.memba.local")
    |> normalize_address()
  end

  defp provider_config do
    Application.get_env(:memba, Memba.Messaging.EmailDeliveryProviders.Postmark, [])
  end

  defp normalize_address({_name, address}), do: address
  defp normalize_address(address), do: address

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
      {:error, {:local_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:local_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:local_delivery_error, {:unexpected_delivery_result, result}}}

  defp record_delivery_fact(:ok, %EmailDeliveryRequest{} = request) do
    LocalDeliveryFacts.record(request)
    :ok
  end

  defp record_delivery_fact(result, %EmailDeliveryRequest{}), do: result
end
