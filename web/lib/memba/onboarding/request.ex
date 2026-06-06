defmodule Memba.Onboarding.Request do
  @moduledoc """
  Ecto source-of-truth record for staff-approved onboarding requests.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Memba.ID
  alias Memba.Membership.EmailAddresses

  @status_active "active"
  @status_converted "converted"
  @status_rejected "rejected"

  @primary_key {:request_id, :string, autogenerate: false}
  schema "onboarding_requests" do
    field :requester_name, :string
    field :requester_email, :string
    field :normalized_requester_email, :string
    field :requester_person_id, :string
    field :requested_club_name, :string
    field :note, :string

    field :status, :string
    field :internal_rejection_notes, :string
    field :triaged_by_staff_email, :string
    field :triaged_at, :utc_datetime_usec
    field :converted_club_id, :string
    field :converted_person_id, :string
    field :converted_membership_id, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def create_changeset(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    %__MODULE__{request_id: ID.generate(:onboarding_request), status: @status_active}
    |> cast(attrs, [:requester_name, :requester_email, :requested_club_name, :note])
    |> trim_changes([:requester_name, :requester_email, :requested_club_name, :note])
    |> validate_required([:requester_name, :requester_email, :requested_club_name, :note])
    |> put_normalized_requester_email()
    |> put_optional_typed_id(
      :requester_person_id,
      Keyword.get(opts, :requester_person_id),
      :person
    )
    |> check_constraint(:status, name: :onboarding_requests_status_check)
  end

  @doc false
  def rejection_changeset(%__MODULE__{} = request, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    request
    |> cast(attrs, [:internal_rejection_notes])
    |> trim_changes([:internal_rejection_notes])
    |> validate_required([:internal_rejection_notes])
    |> put_change(:status, @status_rejected)
    |> put_change(:triaged_at, triaged_at(opts))
    |> put_optional_staff_email(opts)
    |> check_constraint(:status, name: :onboarding_requests_status_check)
  end

  @doc false
  def conversion_changeset(%__MODULE__{} = request, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    request
    |> cast(attrs, [:converted_club_id, :converted_person_id, :converted_membership_id])
    |> trim_changes([:converted_club_id, :converted_person_id, :converted_membership_id])
    |> validate_required([:converted_club_id, :converted_person_id, :converted_membership_id])
    |> validate_typed_id(:converted_club_id, :club)
    |> validate_typed_id(:converted_person_id, :person)
    |> validate_typed_id(:converted_membership_id, :membership)
    |> put_change(:status, @status_converted)
    |> put_change(:triaged_at, triaged_at(opts))
    |> put_optional_staff_email(opts)
    |> check_constraint(:status, name: :onboarding_requests_status_check)
  end

  def status_active, do: @status_active

  defp trim_changes(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      update_change(changeset, field, fn
        value when is_binary(value) -> String.trim(value)
        value -> value
      end)
    end)
  end

  defp put_normalized_requester_email(changeset) do
    case get_field(changeset, :requester_email) do
      email when is_binary(email) and email != "" ->
        case EmailAddresses.normalize_email(email) do
          {:ok, %{email: email, normalized_email: normalized_email}} ->
            changeset
            |> put_change(:requester_email, email)
            |> put_change(:normalized_requester_email, normalized_email)

          {:error, :invalid_email} ->
            add_error(changeset, :requester_email, "is invalid")
        end

      _email ->
        changeset
    end
  end

  defp put_optional_typed_id(changeset, _field, nil, _type), do: changeset

  defp put_optional_typed_id(changeset, field, value, type) do
    case ID.cast(type, value) do
      {:ok, ^value} -> put_change(changeset, field, value)
      :error -> add_error(changeset, field, "is invalid")
    end
  end

  defp validate_typed_id(changeset, field, type) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value ->
        case ID.cast(type, value) do
          {:ok, ^value} -> changeset
          :error -> add_error(changeset, field, "is invalid")
        end
    end
  end

  defp put_optional_staff_email(changeset, opts) do
    case Keyword.fetch(opts, :staff_email) do
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:ok, email} ->
        case EmailAddresses.normalize_email(email) do
          {:ok, %{normalized_email: normalized_email}} ->
            put_change(changeset, :triaged_by_staff_email, normalized_email)

          {:error, :invalid_email} ->
            add_error(changeset, :triaged_by_staff_email, "is invalid")
        end
    end
  end

  defp triaged_at(opts) do
    opts
    |> Keyword.get_lazy(:triaged_at, &DateTime.utc_now/0)
    |> ensure_microsecond_precision()
  end

  defp ensure_microsecond_precision(%DateTime{microsecond: {microsecond, _precision}} = datetime) do
    %DateTime{datetime | microsecond: {microsecond, 6}}
  end
end
