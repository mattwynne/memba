defmodule Memba.Membership.EmailAddressVerificationToken do
  @moduledoc """
  Dedicated persistence schema for Person email-address verification tokens.

  Plaintext verification tokens are never stored here. `token_hash` contains the
  SHA-256 digest of the opaque token delivered to the member.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Memba.ID
  alias Memba.Membership.EmailAddresses

  schema "membership_person_email_address_verification_tokens" do
    field :person_id, :string
    field :normalized_email, :string
    field :token_hash, :binary
    field :expires_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> change(attrs)
    |> validate_required([:person_id, :normalized_email, :token_hash, :expires_at])
    |> validate_person_id()
    |> validate_normalized_email()
    |> validate_token_hash()
    |> foreign_key_constraint(:person_id)
    |> unique_constraint(:token_hash,
      name: :membership_person_email_address_verification_tokens_token_hash_index
    )
  end

  defp validate_person_id(changeset) do
    case get_field(changeset, :person_id) do
      nil ->
        changeset

      person_id ->
        case ID.cast(:person, person_id) do
          {:ok, ^person_id} -> changeset
          :error -> add_error(changeset, :person_id, "is invalid")
        end
    end
  end

  defp validate_normalized_email(changeset) do
    case get_field(changeset, :normalized_email) do
      nil ->
        changeset

      normalized_email ->
        case EmailAddresses.normalize_email(normalized_email) do
          {:ok, %{normalized_email: ^normalized_email}} ->
            changeset

          {:ok, _normalized} ->
            add_error(changeset, :normalized_email, "must already be normalized")

          {:error, :invalid_email} ->
            add_error(changeset, :normalized_email, "is invalid")
        end
    end
  end

  defp validate_token_hash(changeset) do
    case get_field(changeset, :token_hash) do
      nil ->
        changeset

      token_hash when is_binary(token_hash) and byte_size(token_hash) == 32 ->
        changeset

      _token_hash ->
        add_error(changeset, :token_hash, "must be a SHA-256 digest")
    end
  end
end
