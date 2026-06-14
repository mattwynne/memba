defmodule Memba.Accounts do
  @moduledoc """
  Authentication context for shared sign-in-link sign-in.

  This context owns token generation/consumption and role helpers. Membership
  authorization is derived through the public `Memba.Membership` query API.
  """

  import Ecto.Query

  alias Memba.Accounts.AuthEmailRequest
  alias Memba.Accounts.SignInToken
  alias Memba.AuthEmailProgressChanges
  alias Memba.Membership
  alias Memba.Repo

  @sign_in_token_ttl_seconds 15 * 60
  @sign_in_token_bytes 32
  @auth_email_request_progress_ttl_seconds 30 * 60
  @auth_email_request_retention_seconds 7 * 24 * 60 * 60
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
  Request a sign-in link for a staff email or any known email address attached
  to an active member.

  Unknown, invalid, and non-member addresses return `{:ok, nil}` so callers can
  render a neutral response without revealing whether the email is known.
  When a token is created, the returned token is the plaintext value to deliver
  to the user; only its hash is stored.
  """
  def request_sign_in_link(email, opts \\ []) do
    case normalize_email(email) do
      nil ->
        {:ok, nil}

      normalized_email ->
        if eligible_sign_in_email?(normalized_email) do
          create_sign_in_token(normalized_email, opts)
        else
          {:ok, nil}
        end
    end
  end

  @doc """
  Create and persist a new sign-in-link token for a normalized email address.

  The token expires 15 minutes after creation. The plaintext token is returned
  exactly once to the caller and is not persisted.
  """
  def create_sign_in_token(email, opts \\ []) do
    case normalize_email(email) do
      nil ->
        {:error, :invalid_email}

      normalized_email ->
        token = generate_sign_in_token()
        now = timestamp(opts)
        expires_at = DateTime.add(now, @sign_in_token_ttl_seconds, :second)

        attrs = %{
          email: normalized_email,
          token_hash: hash_sign_in_token(token),
          expires_at: expires_at
        }

        case attrs |> SignInToken.create_changeset() |> Repo.insert() do
          {:ok, %SignInToken{} = sign_in_token} ->
            {:ok,
             %{email: sign_in_token.email, token: token, expires_at: sign_in_token.expires_at}}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Generate an opaque URL-safe token for sign-in-link delivery.
  """
  def generate_sign_in_token do
    @sign_in_token_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Hash a plaintext sign-in-link token for server-side storage and lookup.
  """
  def hash_sign_in_token(token) when is_binary(token) do
    :crypto.hash(:sha256, token)
  end

  @doc """
  Consume a sign-in-link token exactly once.

  Returns `{:ok, %{email: email}}` when the token is known, unexpired, and not
  previously consumed. Unknown, expired, and already-consumed tokens return safe
  error atoms suitable for mapping to a generic UI error.
  """
  def consume_sign_in_token(token, opts \\ [])

  def consume_sign_in_token(token, opts) when is_binary(token) do
    token_hash = hash_sign_in_token(token)
    now = timestamp(opts)

    Repo.transaction(fn ->
      SignInToken
      |> where([sign_in_token], sign_in_token.token_hash == ^token_hash)
      |> lock("FOR UPDATE")
      |> Repo.one()
      |> consume_locked_sign_in_token(now)
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  def consume_sign_in_token(_token, _opts), do: {:error, :not_found}

  @doc """
  Create a short-lived auth-email progress request.

  The returned request has an opaque public ID. The optional `:recipient_email`
  attribute is normalized and should only be supplied by callers that already
  need to persist the real delivery address for a known auth email send.
  """
  def create_auth_email_request(attrs \\ %{}, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = timestamp(opts)

    attrs
    |> AuthEmailRequest.create_changeset(
      now: now,
      expires_at: DateTime.add(now, @auth_email_request_progress_ttl_seconds, :second),
      retain_until: DateTime.add(now, @auth_email_request_retention_seconds, :second)
    )
    |> Repo.insert()
  end

  @doc """
  Fetch an auth-email progress request by its opaque public request ID.
  """
  def get_auth_email_request(request_id) do
    with {:ok, request_id} <- Memba.ID.cast(:auth_email_request, request_id) do
      Repo.get(AuthEmailRequest, request_id)
    else
      :error -> nil
    end
  end

  @doc """
  Return whether the request is past its 30-minute user-facing progress window.
  """
  def auth_email_request_expired?(%AuthEmailRequest{} = request, opts \\ []) do
    now = timestamp(opts)
    DateTime.compare(request.expires_at, now) != :gt
  end

  @doc """
  Mark an auth-email request as handed to the email provider.
  """
  def mark_auth_email_sent(request_id, attrs \\ %{}, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    update_auth_email_request(request_id, fn request ->
      request
      |> AuthEmailRequest.sent_changeset(attrs, now: timestamp(opts))
      |> Repo.update()
    end)
    |> publish_auth_email_progress_change()
  end

  @doc """
  Record that the recipient mailbox provider accepted the auth email.
  """
  def record_auth_email_provider_accepted(request_id, attrs \\ %{}, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    record_auth_email_provider_progress(
      request_id,
      AuthEmailRequest.status_provider_accepted(),
      attrs,
      opts
    )
  end

  @doc """
  Record that the provider reported delayed auth-email delivery.
  """
  def record_auth_email_provider_delayed(request_id, attrs \\ %{}, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    record_auth_email_provider_progress(
      request_id,
      AuthEmailRequest.status_provider_delayed(),
      attrs,
      opts
    )
  end

  @doc """
  Record that the provider reported failed auth-email delivery.
  """
  def record_auth_email_provider_failed(request_id, attrs \\ %{}, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    record_auth_email_provider_progress(
      request_id,
      AuthEmailRequest.status_provider_failed(),
      attrs,
      opts
    )
  end

  @doc """
  Delete auth-email request rows whose seven-day retention window has elapsed.
  """
  def delete_retained_auth_email_requests(opts \\ []) do
    now = timestamp(opts)

    AuthEmailRequest
    |> where([request], request.retain_until <= ^now)
    |> Repo.delete_all()
  end

  @doc """
  List active clubs for a signed-in email address.

  Results are ordered by the Membership context's club listing order.
  """
  def list_active_clubs_for_email(email) do
    case normalize_email(email) do
      nil ->
        []

      normalized_email ->
        Membership.list_active_clubs_for_member_email(normalized_email)
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
        Membership.active_member_of_club_by_email?(club_id, normalized_email)
    end
  end

  defp eligible_sign_in_email?(email) do
    staff_email?(email) or list_active_clubs_for_email(email) != []
  end

  defp consume_locked_sign_in_token(nil, _now), do: {:error, :not_found}

  defp consume_locked_sign_in_token(%SignInToken{consumed_at: %DateTime{}} = _sign_in_token, _now) do
    {:error, :consumed}
  end

  defp consume_locked_sign_in_token(%SignInToken{} = sign_in_token, now) do
    if DateTime.compare(sign_in_token.expires_at, now) == :gt do
      sign_in_token
      |> SignInToken.consume_changeset(now)
      |> Repo.update()
      |> case do
        {:ok, %SignInToken{} = consumed_token} -> {:ok, %{email: consumed_token.email}}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, :expired}
    end
  end

  defp record_auth_email_provider_progress(request_id, status, attrs, opts) do
    update_auth_email_request(request_id, fn request ->
      request
      |> AuthEmailRequest.provider_progress_changeset(status, attrs, now: timestamp(opts))
      |> Repo.update()
    end)
    |> publish_auth_email_progress_change()
  end

  defp publish_auth_email_progress_change({:ok, %AuthEmailRequest{} = request} = result) do
    _result = AuthEmailProgressChanges.publish(request.request_id)
    result
  end

  defp publish_auth_email_progress_change(result), do: result

  defp update_auth_email_request(request_id, update_fun) when is_function(update_fun, 1) do
    with {:ok, request_id} <- Memba.ID.cast(:auth_email_request, request_id) do
      request_id
      |> transact_auth_email_request_update(update_fun)
      |> unwrap_auth_email_request_update()
    else
      :error -> {:error, :not_found}
    end
  end

  defp transact_auth_email_request_update(request_id, update_fun) do
    Repo.transaction(fn ->
      case lock_auth_email_request(request_id) do
        nil ->
          Repo.rollback(:not_found)

        %AuthEmailRequest{} = request ->
          case update_fun.(request) do
            {:ok, %AuthEmailRequest{} = request} -> request
            {:error, changeset} -> Repo.rollback(changeset)
          end
      end
    end)
  end

  defp lock_auth_email_request(request_id) do
    AuthEmailRequest
    |> where([request], request.request_id == ^request_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  defp unwrap_auth_email_request_update({:ok, %AuthEmailRequest{} = request}), do: {:ok, request}
  defp unwrap_auth_email_request_update({:error, reason}), do: {:error, reason}

  defp timestamp(opts) do
    Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)
  end
end
