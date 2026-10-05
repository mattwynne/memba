defmodule Memba.Messaging.MessageSourceQueries do
  @moduledoc """
  Projection-backed lookups for outbound Message-ID references and inbound
  provider source records. These reads do not determine inbound idempotency.
  """

  import Ecto.Query

  alias Memba.Messaging.OutboundMessageID
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def get_outbound_message_reference(rfc_message_id) do
    with message_id when is_binary(message_id) <- OutboundMessageID.normalize(rfc_message_id) do
      EmailDeliveryProjection
      |> join(:inner, [delivery], message in MessageProjection,
        on: message.message_id == delivery.message_id
      )
      |> where([delivery, _message], delivery.outbound_message_id == ^message_id)
      |> select([delivery, message], %{
        outbound_message_id: delivery.outbound_message_id,
        delivery_id: delivery.delivery_id,
        message_id: message.message_id,
        conversation_id: message.conversation_id,
        club_id: message.club_id
      })
      |> Repo.one()
    else
      nil -> nil
    end
  end

  def get_inbound_email_source(provider, provider_message_id)
      when is_binary(provider) and is_binary(provider_message_id) do
    provider = normalize_inbound_source_lookup(provider)
    provider_message_id = normalize_inbound_source_lookup(provider_message_id)

    if provider == "" or provider_message_id == "" do
      nil
    else
      Repo.get_by(InboundEmailSourceProjection,
        provider: provider,
        provider_message_id: provider_message_id
      )
    end
  end

  def get_inbound_email_source(_provider, _provider_message_id), do: nil

  defp normalize_inbound_source_lookup(value) do
    value
    |> String.trim()
    |> String.downcase()
  end
end
