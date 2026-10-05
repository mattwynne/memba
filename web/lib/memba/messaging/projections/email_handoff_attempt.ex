defmodule Memba.Messaging.Projections.EmailHandoffAttempt do
  @moduledoc "Operational, durable record of a possible provider handoff (not a domain event)."
  use Ecto.Schema

  schema "messaging_email_handoff_attempts" do
    field :delivery_id, :string
    field :provider, :string
    field :request, :binary
    field :state, :string
    field :detail, :string
    field :started_at, :utc_datetime_usec
    field :resolved_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end
end
