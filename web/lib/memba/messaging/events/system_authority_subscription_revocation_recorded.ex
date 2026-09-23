defmodule Memba.Messaging.Events.SystemAuthoritySubscriptionRevocationRecorded do
  @moduledoc "Durable tombstone for one derived system-authority lifecycle."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :club_id,
    :club_membership_id,
    :authority_kind,
    :authority_through_club_stream_version,
    :revocation_id
  ]
  defstruct @enforce_keys
end
