defmodule Memba.Accounts do
  @moduledoc """
  Authentication context for shared magic-link sign-in.

  This context owns token generation/consumption and role helpers. Membership
  authorization is derived through the public `Memba.Membership` query API.
  """

  import Ecto.Query

  alias Memba.Accounts.MagicToken
  alias Memba.Membership
  alias Memba.Repo

  @magic_token_ttl_seconds 15 * 60
  @magic_token_bytes 32
  @staff_domain "memba.io"

  @doc """
  Normalize an email address for authentication lookups.

  Returns `nil` for non-binary or blank inputs.
  """
  def normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized_email -> normalized_email
    end
  end

  def normalize_email(_email), do: nil

  @doc """
  Return whether an email belongs to the Memba staff domain.

  Staff authorization is intentionally simple for this product slice: a
  signed-in address with the exact `memba.io` domain is staff.
  """
  def staff_email?(email) do
    case normalize_email(email) do
      nil ->
        false

      normalized_email ->
        case String.split(normalized_email, "@") do
          [local_part, @staff_domain] -> local_part != ""
          _other -> false
        end
    end
  end

  @doc """
  Request a magic link for a staff or active member email.

  Unknown, invalid, and non-member addresses return `{:ok, nil}` so callers can
  render a neutral response without revealing whether the email is known.
  When a token is created, the returned token is the plaintext value to deliver
  to the user; only its hash is stored.
  """
  def request_magic_link(email, opts \\ []) do
    case normalize_email(email) do
      nil ->
        {:ok, nil}

      normalized_email ->
        if magic_link_recipient?(normalized_email) do
          create_magic_token(normalized_email, opts)
        else
          {:ok, nil}
        end
    end
  end

  @doc """
  Create and persist a new magic-link token for a normalized email address.

  The token expires 15 minutes after creation. The plaintext token is returned
  exactly once to the caller and is not persisted.
  """
  def create_magic_token(email, opts \\ []) do
    case normalize_email(email) do
      nil ->
        {:error, :invalid_email}

      normalized_email ->
        token = generate_magic_token()
        now = timestamp(opts)
        expires_at = DateTime.add(now, @magic_token_ttl_seconds, :second)

        attrs = %{
          email: normalized_email,
          token_hash: hash_magic_token(token),
          expires_at: expires_at
        }

        case attrs |> MagicToken.create_changeset() |> Repo.insert() do
          {:ok, %MagicToken{} = magic_token} ->
            {:ok, %{email: magic_token.email, token: token, expires_at: magic_token.expires_at}}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Generate an opaque URL-safe token for magic-link delivery.
  """
  def generate_magic_token do
    @magic_token_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Hash a plaintext magic-link token for server-side storage and lookup.
  """
  def hash_magic_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  @doc """
  Consume a magic-link token exactly once.

  Returns `{:ok, %{email: email}}` when the token is known, unexpired, and not
  previously consumed. Unknown, expired, and already-consumed tokens return safe
  error atoms suitable for mapping to a generic UI error.
  """
  def consume_magic_token(token, opts \\ [])

  def consume_magic_token(token, opts) when is_binary(token) do
    token_hash = hash_magic_token(token)
    now = timestamp(opts)

    Repo.transaction(fn ->
      MagicToken
      |> where([magic_token], magic_token.token_hash == ^token_hash)
      |> lock("FOR UPDATE")
      |> Repo.one()
      |> consume_locked_magic_token(now)
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  def consume_magic_token(_token, _opts), do: {:error, :not_found}

  @doc """
  List active clubs for a signed-in email address.

  Results are ordered by the Membership context's club listing order.
  """
  def list_active_clubs_for_email(email) do
    case normalize_email(email) do
      nil ->
        []

      normalized_email ->
        Membership.list_clubs()
        |> Enum.filter(&active_member_of_club?(&1.club_id, normalized_email))
    end
  end

  @doc """
  Return whether an email belongs to an active member of the given club.
  """
  def active_member_of_club?(club_id, email) do
    case normalize_email(email) do
      nil ->
        false

      normalized_email ->
        club_id
        |> Membership.list_active_members_of_club()
        |> Enum.any?(fn member -> normalize_email(member.email) == normalized_email end)
    end
  end

  defp magic_link_recipient?(email) do
    staff_email?(email) or list_active_clubs_for_email(email) != []
  end

  defp consume_locked_magic_token(nil, _now), do: {:error, :not_found}

  defp consume_locked_magic_token(%MagicToken{consumed_at: %DateTime{}} = _magic_token, _now) do
    {:error, :consumed}
  end

  defp consume_locked_magic_token(%MagicToken{} = magic_token, now) do
    if DateTime.compare(magic_token.expires_at, now) == :gt do
      magic_token
      |> MagicToken.consume_changeset(now)
      |> Repo.update()
      |> case do
        {:ok, %MagicToken{} = consumed_token} -> {:ok, %{email: consumed_token.email}}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, :expired}
    end
  end

  defp timestamp(opts) do
    Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
  end
end
