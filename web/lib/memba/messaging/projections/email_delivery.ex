defmodule Memba.Messaging.Projections.EmailDelivery do
  @moduledoc """
  Read model projection for one email delivery belonging to a message.

  Valid persisted statuses are defined in `Memba.Messaging.EmailDeliveryStatus`
  and enforced by the `messaging_email_deliveries_status_check` database
  constraint.

  Dispatch diagnostics are intentionally operational rather than domain facts:

    * `attempt_count` counts durable possible provider handoffs, including
      first-pass successes and attempts interrupted before the HTTP call.
    * `last_dispatch_attempted_at` records when the dispatcher most recently
      claimed the delivery for a provider handoff, whether that handoff later
      succeeds or fails.
    * `sent_at` records confirmed provider acceptance. `uncertain` explicitly
      means acceptance could not be established; individual attempts preserve
      their own outcomes in `messaging_email_handoff_attempts`.

  `outbound_message_id` is the Memba-controlled RFC Message-ID sent in the
  outbound email. The database keeps it non-null and unique so inbound reply
  routing can use it as a deterministic lookup key.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :string, autogenerate: false}
  schema "messaging_email_deliveries" do
    field :message_id, :string
    field :outbound_message_id, :string
    field :recipient_id, :string
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string
    field :attempt_count, :integer, default: 0
    field :active_attempt_id, :integer
    field :claim_version, :integer, default: 0
    field :latest_error, :string
    field :latest_detail, :string
    field :last_dispatch_attempted_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end
end
