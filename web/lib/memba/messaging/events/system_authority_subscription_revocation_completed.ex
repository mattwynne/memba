defmodule Memba.Messaging.Events.SystemAuthoritySubscriptionRevocationCompleted do
  @moduledoc "Durable completion receipt for one system-authority revocation."
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
