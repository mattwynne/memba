defmodule Memba.Messaging.Projections.EmailDelivery do
  @moduledoc """
  Read model projection for one email delivery belonging to a message.

  Dispatch diagnostics are intentionally operational rather than domain facts:

    * `attempt_count` remains `0` for first-pass successes, increments when a
      provider handoff fails, and increments for a manual retry that succeeds so
      a previously-failed delivery shows how many provider attempts were needed.
    * `last_dispatch_attempted_at` records when the dispatcher most recently
      claimed the delivery for a provider handoff, whether that handoff later
      succeeds or fails.
    * `sent_at` and `failed_at` record the latest persisted dispatch outcome.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :string, autogenerate: false}
  schema "messaging_email_deliveries" do
    field :message_id, :string
    field :recipient_id, :string
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string
    field :attempt_count, :integer, default: 0
    field :latest_error, :string
    field :latest_detail, :string
    field :last_dispatch_attempted_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end
end
