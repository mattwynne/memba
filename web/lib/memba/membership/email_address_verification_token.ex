defmodule Memba.Membership.EmailAddressVerificationToken do
  @moduledoc """
  Dedicated persistence schema for Person email-address verification tokens.

  Plaintext verification tokens are never stored here. `token_hash` contains the
  SHA-256 digest of the opaque token delivered to the member.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.EmailAddresses
  alias Memba.Repo

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

  def consume_changeset(%__MODULE__{} = verification_token, consumed_at) do
    verification_token
    |> change(consumed_at: consumed_at)
    |> validate_required([:consumed_at])
  end

  def revoke_changeset(%__MODULE__{} = verification_token, revoked_at) do
    verification_token
    |> change(revoked_at: revoked_at)
    |> validate_required([:revoked_at])
  end

  def insert(attrs) when is_map(attrs) do
    attrs
    |> create_changeset()
    |> Repo.insert()
  end

  def consume(token_hash, consumed_at, scope_fun)
      when is_binary(token_hash) and is_function(scope_fun, 1) do
    Repo.transaction(fn ->
      __MODULE__
      |> where([verification_token], verification_token.token_hash == ^token_hash)
      |> lock("FOR UPDATE")
      |> Repo.one()
      |> consume_locked(consumed_at, scope_fun)
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  def revoke_pending(person_id, normalized_email, revoked_at)
      when is_binary(person_id) and is_binary(normalized_email) do
    {_count, nil} =
      __MODULE__
      |> where([verification_token], verification_token.person_id == ^person_id)
      |> where([verification_token], verification_token.normalized_email == ^normalized_email)
      |> where([verification_token], is_nil(verification_token.consumed_at))
      |> where([verification_token], is_nil(verification_token.revoked_at))
      |> Repo.update_all(set: [revoked_at: revoked_at, updated_at: revoked_at])

    :ok
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

  defp consume_locked(nil, _consumed_at, _scope_fun), do: {:error, :not_found}

  defp consume_locked(%__MODULE__{consumed_at: %DateTime{}}, _consumed_at, _scope_fun) do
    {:error, :consumed}
  end

  defp consume_locked(%__MODULE__{revoked_at: %DateTime{}}, _consumed_at, _scope_fun) do
    {:error, :revoked}
  end

  defp consume_locked(%__MODULE__{} = verification_token, consumed_at, scope_fun) do
    with :ok <- ensure_unexpired(verification_token, consumed_at),
         {:ok, scope} <- scope_fun.(verification_token),
         {:ok, %__MODULE__{}} <-
           verification_token
           |> consume_changeset(consumed_at)
           |> Repo.update() do
      {:ok, scope}
    else
      {:error, _reason} = error -> error
    end
  end

  defp ensure_unexpired(%__MODULE__{} = verification_token, now) do
    if DateTime.compare(verification_token.expires_at, now) == :gt do
      :ok
    else
      {:error, :expired}
    end
  end
end
