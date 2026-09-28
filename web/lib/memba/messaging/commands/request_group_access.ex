defmodule Memba.Messaging.Commands.RequestGroupAccess do
  @moduledoc """
  Application-layer intent to ask a club's Admin group for custom-group access.

  This composite command is handled by `Memba.Messaging`; it is deliberately
  not registered with the Messaging router or persisted as its own aggregate.
  The caller supplies only the stable message identity, authenticated club and
  requester identities, and target group identity. Messaging derives the
  constituent `SendMessage` facts server-side.
  """

  @enforce_keys [:message_id, :club_id, :requester_person_id, :group_id]
  defstruct [:message_id, :club_id, :requester_person_id, :group_id]
end
