defmodule Memba.Messaging.Commands.RevokeSystemConversationSubscriptions do
  @moduledoc "Revokes grants backed by one exact derived system-authority lifecycle."

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
