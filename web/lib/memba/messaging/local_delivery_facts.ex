defmodule Memba.Messaging.LocalDeliveryFacts do
  @moduledoc """
  In-memory delivery facts recorded by the local email delivery provider.

  Browser acceptance tests use these facts to assert that the application handed
  message emails to the local provider without polling Swoosh's developer mailbox
  preview.
  """

  use Agent

  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.MemberMessageEmail

  @name __MODULE__

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: @name)
  end

  @doc "Record a successfully delivered local-provider email request."
  def record(%EmailDeliveryRequest{} = request) do
    fact = %{
      id: request.delivery_id,
      message_id: request.message_id,
      outbound_message_id: request.outbound_message_id,
      club_id: request.club_id,
      delivery_id: request.delivery_id,
      recipient_id: request.recipient_id,
      recipient_name: request.recipient_name,
      recipient_address: request.recipient_address,
      sender_name: request.sender_name,
      sender_address: request.sender_address,
      from: "#{MemberMessageEmail.from_display_name(request)} <#{from_address()}>",
      to: ["#{request.recipient_name} <#{request.recipient_address}>"],
      subject: MemberMessageEmail.subject(request),
      text_body: MemberMessageEmail.text_body(request),
      metadata: %{
        "memba_message_id" => request.message_id,
        "memba_delivery_id" => request.delivery_id,
        "memba_club_id" => request.club_id
      }
    }

    Agent.update(@name, fn facts -> [fact | facts] end)
    :ok
  end

  @doc "List recorded facts in delivery order."
  def list do
    Agent.get(@name, &Enum.reverse/1)
  end

  @doc "Clear recorded facts. Intended for tests."
  def reset do
    Agent.update(@name, fn _facts -> [] end)
  end

  defp from_address do
    :memba
    |> Application.get_env(Memba.Messaging.EmailDeliveryProviders.Postmark, [])
    |> Keyword.get(:from, "messages@mail.memba.local")
    |> normalize_address()
  end

  defp normalize_address({_name, address}), do: address
  defp normalize_address(address), do: address
end
