defmodule Memba.Accounts.AuthEmailRequest do
  @moduledoc """
  Short-lived source-of-truth record for sign-in-link email delivery progress.

  The public identifier is an opaque typed request ID. Recipient email is
  optional and stores only the normalized internal delivery address when later
  steps need to correlate a real auth email send.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Memba.Accounts
  alias Memba.ID

  @status_created "created"
  @status_sent "sent"
  @status_provider_accepted "provider_accepted"
  @status_provider_delayed "provider_delayed"
  @status_provider_failed "provider_failed"

  @statuses [
    @status_created,
    @status_sent,
    @status_provider_accepted,
    @status_provider_delayed,
    @status_provider_failed
  ]

  @primary_key {:request_id, :string, autogenerate: false}
  schema "auth_email_requests" do
    field :recipient_email, :string
    field :status, :string

    field :provider, :string
    field :provider_message_id, :string
    field :provider_message_stream, :string
    field :provider_event_id, :string
    field :provider_event_type, :string
    field :provider_reason, :string

    field :sent_at, :utc_datetime_usec
    field :provider_reported_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    field :retain_until, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(attrs, opts) when is_map(attrs) and is_list(opts) do
    %__MODULE__{
      request_id: ID.generate(:auth_email_request),
      status: @status_created,
      expires_at: Keyword.fetch!(opts, :expires_at),
      retain_until: Keyword.fetch!(opts, :retain_until)
    }
    |> change()
    |> put_optional_recipient_email(attrs)
    |> validate_required([:request_id, :status, :expires_at, :retain_until])
    |> validate_common()
    |> check_constraint(:status, name: :auth_email_requests_status_check)
    |> check_constraint(:retain_until, name: :auth_email_requests_retain_after_expiry_check)
  end

  def sent_changeset(%__MODULE__{} = request, attrs, opts)
      when is_map(attrs) and is_list(opts) do
    now = Keyword.fetch!(opts, :now)

    request
    |> change(status: @status_sent, sent_at: now)
    |> put_optional_recipient_email(attrs)
    |> put_provider_attrs(attrs)
    |> validate_required([:status, :sent_at])
    |> validate_common()
    |> check_constraint(:status, name: :auth_email_requests_status_check)
  end

  def provider_progress_changeset(%__MODULE__{} = request, status, attrs, opts)
      when status in [
             @status_provider_accepted,
             @status_provider_delayed,
             @status_provider_failed
           ] and
             is_map(attrs) and is_list(opts) do
    now = Keyword.fetch!(opts, :now)

    request
    |> change(status: status, provider_reported_at: now)
    |> put_provider_attrs(attrs)
    |> validate_required([:status, :provider_reported_at])
    |> validate_common()
    |> check_constraint(:status, name: :auth_email_requests_status_check)
  end

  def status_created, do: @status_created
  def status_sent, do: @status_sent
  def status_provider_accepted, do: @status_provider_accepted
  def status_provider_delayed, do: @status_provider_delayed
  def status_provider_failed, do: @status_provider_failed

  defp validate_common(changeset) do
    changeset
    |> validate_inclusion(:status, @statuses)
    |> validate_typed_request_id()
    |> validate_retention_after_expiry()
  end

  defp validate_typed_request_id(changeset) do
    case get_field(changeset, :request_id) do
      nil ->
        changeset

      request_id ->
        case ID.cast(:auth_email_request, request_id) do
          {:ok, ^request_id} -> changeset
          :error -> add_error(changeset, :request_id, "is invalid")
        end
    end
  end

  defp validate_retention_after_expiry(changeset) do
    expires_at = get_field(changeset, :expires_at)
    retain_until = get_field(changeset, :retain_until)

    if expires_at && retain_until && DateTime.compare(retain_until, expires_at) != :gt do
      add_error(changeset, :retain_until, "must be after expiry")
    else
      changeset
    end
  end

  defp put_optional_recipient_email(changeset, attrs) do
    case fetch_attr(attrs, :recipient_email) do
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:ok, email} when is_binary(email) ->
        case Accounts.normalize_email(email) do
          nil -> add_error(changeset, :recipient_email, "can't be blank")
          normalized_email -> put_change(changeset, :recipient_email, normalized_email)
        end

      {:ok, _email} ->
        add_error(changeset, :recipient_email, "is invalid")
    end
  end

  defp put_provider_attrs(changeset, attrs) do
    Enum.reduce(
      [
        :provider,
        :provider_message_id,
        :provider_message_stream,
        :provider_event_id,
        :provider_event_type,
        :provider_reason
      ],
      changeset,
      fn field, changeset ->
        put_optional_trimmed_string(changeset, attrs, field)
      end
    )
  end

  defp put_optional_trimmed_string(changeset, attrs, field) do
    case fetch_attr(attrs, field) do
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:ok, value} when is_binary(value) ->
        case String.trim(value) do
          "" -> changeset
          trimmed_value -> put_change(changeset, field, trimmed_value)
        end

      {:ok, _value} ->
        add_error(changeset, field, "is invalid")
    end
  end

  defp fetch_attr(attrs, key) when is_map(attrs) do
    string_key = Atom.to_string(key)

    case Map.fetch(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(attrs, string_key)
    end
  end
end
