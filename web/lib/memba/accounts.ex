defmodule Memba.Accounts do
  @moduledoc """
  Authentication context for shared email magic-link sign-in.

  The context owns magic-token generation and consumption while delegating club
  membership decisions to the public Membership query API.
  """

  import Ecto.Query

  alias Memba.Accounts.MagicToken
  alias Memba.Membership
  alias Memba.Repo

  @magic_token_bytes 32
  @magic_token_ttl_minutes 15
  @staff_domain "memba.io"

  @doc """
  Normalize an email address for authentication lookups.
  """
  def normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if valid_email?(email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  def normalize_email(_email), do: {:error, :invalid_email}

  @doc """
  Return whether an email address belongs to Memba staff.
  """
  def staff_email?(email) do
    case normalize_email(email) do
      {:ok, email} -> String.ends_with?(email, "@#{@staff_domain}")
      {:error, :invalid_email} -> false
    end
  end

  @doc """
  Request a magic-link token for an email that is allowed to sign in.

  Staff emails and active member emails receive a token request map containing
  the normalized email, raw token, and expiry. Valid but unknown emails return
  `{:ok, :not_requested}` so callers can keep user-facing responses neutral.
  """
  def request_magic_link(email, opts \\ []) when is_list(opts) do
    with {:ok, email} <- normalize_email(email) do
      if sign_in_allowed?(email) do
        create_magic_token(email, opts)
      else
        {:ok, :not_requested}
      end
    end
  end

  @doc """
  Create and persist a one-time magic-link token for a normalized email.

  Only the SHA-256 hash is stored; the raw token is returned once to the caller.
  """
  def create_magic_token(email, opts \\ []) when is_list(opts) do
    with {:ok, email} <- normalize_email(email) do
      now = Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
      token = Keyword.get_lazy(opts, :token, &generate_magic_token/0)
      expires_at = DateTime.add(now, @magic_token_ttl_minutes, :minute)

      {:ok, _magic_token} =
        Repo.insert(%MagicToken{
          email: email,
          token_hash: hash_magic_token(token),
          expires_at: expires_at
        })

      {:ok, %{email: email, token: token, expires_at: expires_at}}
    end
  end

  @doc """
  Hash a raw magic-link token for persistence or lookup.
  """
  def hash_magic_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  @doc """
  Consume a valid, unexpired magic-link token exactly once.
  """
  def consume_magic_token(token, opts \\ [])

  def consume_magic_token(token, opts) when is_binary(token) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
    token_hash = hash_magic_token(token)

    query =
      MagicToken
      |> where([magic_token], magic_token.token_hash == ^token_hash)
      |> where([magic_token], is_nil(magic_token.consumed_at))
      |> where([magic_token], magic_token.expires_at > ^now)
      |> select([magic_token], magic_token.email)

    case Repo.update_all(query, set: [consumed_at: now, updated_at: now]) do
      {1, [email]} -> {:ok, email}
      {0, []} -> {:error, :invalid_or_expired_token}
    end
  end

  def consume_magic_token(_token, _opts), do: {:error, :invalid_or_expired_token}

  @doc """
  List active clubs for an email address.
  """
  def list_clubs_for_email(email) do
    with {:ok, email} <- normalize_email(email) do
      Membership.list_clubs()
      |> Enum.filter(&active_member_of_club?(email, &1.club_id))
    else
      {:error, :invalid_email} -> []
    end
  end

  @doc """
  Return whether an email address is an active member of the given club.
  """
  def active_member_of_club?(email, club_id) do
    with {:ok, email} <- normalize_email(email) do
      club_id
      |> Membership.list_active_members_of_club()
      |> Enum.any?(fn member -> member.email == email end)
    else
      {:error, :invalid_email} -> false
    end
  end

  defp sign_in_allowed?(email) do
    staff_email?(email) or list_clubs_for_email(email) != []
  end

  defp generate_magic_token do
    @magic_token_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp valid_email?(email) do
    case String.split(email, "@") do
      [local, domain] -> local != "" and domain != "" and String.contains?(domain, ".")
      _other -> false
    end
  end
end
