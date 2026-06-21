defmodule Memba.Messaging.OutboundMessageID do
  @moduledoc """
  Generates Memba-controlled RFC Message-ID values for outbound member emails.

  The value is deterministic from Memba's stable delivery and message IDs so the
  read-model mapping can be rebuilt from projected delivery rows.
  """

  @domain "messages.memba.io"

  @doc "Return the RFC Message-ID for one outbound member-message delivery."
  def for_delivery(delivery_id, message_id)
      when is_binary(delivery_id) and is_binary(message_id) do
    "<memba.#{delivery_id}.#{message_id}@#{@domain}>"
  end

  @doc "Normalize a provider-supplied Message-ID for lookup."
  def normalize(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      <<"<", _rest::binary>> = message_id ->
        message_id

      message_id ->
        "<#{message_id}>"
    end
  end

  def normalize(_value), do: nil
end
