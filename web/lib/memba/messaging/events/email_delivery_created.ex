defmodule Memba.Messaging.Events.EmailDeliveryCreated do
  @moduledoc """
  Event raised for one email delivery belonging to a sent message.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id, :recipient_id, :recipient_name, :recipient_email]
  defstruct [
    :message_id,
    :delivery_id,
    :recipient_id,
    :recipient_name,
    :recipient_email,
    :subscription_authorization_id,
    :authority_decision_id,
    :authority_kind,
    :authority_club_id,
    :authority_club_membership_id,
    :authority_group_membership_id,
    :authority_club_stream_version
  ]
end
