defmodule Memba.Membership.PersonEmailVerification do
  @moduledoc """
  Coordinates pending Person email verification, token issuance and consumption.

  Preparation stays in PersonEmailAddressCommands; CommandDispatch is the only
  Commanded adapter. The token store locks consumption and enforces one-use/TTL.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Repo

  alias Memba.Membership.{
    CommandDispatch,
    EmailAddresses,
    EmailAddressVerificationToken,
    InvitationToken,
    PersonEmailAddressCommands,
    PersonEmailAddressVerificationRevocation
  }

  alias Memba.Membership.Projections.PersonEmailAddress

  @token_ttl_seconds 15 * 60

  def replace(attrs, dispatch_opts) do
    {revoker, dispatch_opts} = PersonEmailAddressVerificationRevocation.revoker(dispatch_opts)

    with {:ok, command, requests} <- PersonEmailAddressCommands.prepare_replace(attrs) do
      command
      |> CommandDispatch.dispatch(dispatch_opts)
      |> PersonEmailAddressVerificationRevocation.after_dispatch(requests, revoker)
    end
  end

  def remove(attrs, dispatch_opts) do
    {revoker, dispatch_opts} = PersonEmailAddressVerificationRevocation.revoker(dispatch_opts)

    with {:ok, command, requests} <- PersonEmailAddressCommands.prepare_remove(attrs) do
      command
      |> CommandDispatch.dispatch(dispatch_opts)
      |> PersonEmailAddressVerificationRevocation.after_dispatch(requests, revoker)
    end
  end

  def resend(attrs, opts) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, person_id} <- cast_person_id(person_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email),
         {:ok, email_address} <- pending_address(person_id, normalized_email) do
      email_address
      |> verification_request()
      |> issue(opts)
    end
  end

  def consume(token, opts) when is_binary(token) and is_list(opts) do
    EmailAddressVerificationToken.consume(hash_token(token), timestamp(opts), fn token_row ->
      with {:ok, address} <- pending_address(token_row.person_id, token_row.normalized_email) do
        {:ok, verification_request(address)}
      end
    end)
  end

  def consume(_token, _opts), do: {:error, :not_found}

  def verify(attrs, dispatch_opts) do
    with {:ok, command} <- PersonEmailAddressCommands.prepare_verify(attrs) do
      CommandDispatch.dispatch(command, dispatch_opts)
    end
  end

  def verify_for_sign_in(email, dispatch_opts) do
    case pending_for_sign_in(email) do
      {:ok, %PersonEmailAddress{} = address} ->
        address
        |> verification_request()
        |> verify(dispatch_opts)
        |> normalize_sign_in_result()

      :not_pending ->
        :ok
    end
  end

  defp pending_address(person_id, normalized_email) do
    PersonEmailAddress
    |> where([address], address.person_id == ^person_id)
    |> where([address], address.normalized_email == ^normalized_email)
    |> limit(1)
    |> Repo.one()
    |> ensure_pending()
  end

  defp pending_for_sign_in(email) do
    case normalize_email(email) do
      nil ->
        :not_pending

      normalized_email ->
        PersonEmailAddress
        |> where([address], address.normalized_email == ^normalized_email)
        |> where([address], is_nil(address.verified_at))
        |> limit(1)
        |> Repo.one()
        |> case do
          %PersonEmailAddress{} = address -> {:ok, address}
          nil -> :not_pending
        end
    end
  end

  defp ensure_pending(nil), do: {:error, :pending_email_address_not_found}
  defp ensure_pending(%PersonEmailAddress{verified_at: nil} = address), do: {:ok, address}

  defp ensure_pending(%PersonEmailAddress{verified_at: %DateTime{}}),
    do: {:error, :email_address_already_verified}

  defp verification_request(%PersonEmailAddress{} = address) do
    %{
      person_id: address.person_id,
      email: address.email,
      normalized_email: address.normalized_email
    }
  end

  defp issue(request, opts) do
    issuer =
      case Keyword.fetch(opts, :verification_issuer) do
        {:ok, issuer} -> issuer
        :error -> fn request -> default_issuer(request, opts) end
      end

    result =
      if is_function(issuer, 1),
        do: issuer.(request),
        else: {:error, :invalid_email_address_verification_issuer}

    case result do
      :ok -> {:ok, request}
      {:ok, issuer_result} -> {:ok, Map.put(request, :issuer_result, issuer_result)}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected_email_address_verification_issuer_result, other}}
    end
  end

  defp default_issuer(request, opts) do
    token = InvitationToken.generate_token()
    expires_at = DateTime.add(timestamp(opts), @token_ttl_seconds, :second)

    attrs = %{
      person_id: request.person_id,
      normalized_email: request.normalized_email,
      token_hash: hash_token(token),
      expires_at: expires_at
    }

    case EmailAddressVerificationToken.insert(attrs) do
      {:ok, %EmailAddressVerificationToken{} = row} ->
        {:ok, %{token: token, expires_at: row.expires_at}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp hash_token(token), do: :crypto.hash(:sha256, token)
  defp timestamp(opts), do: Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)

  defp normalize_sign_in_result(:ok), do: :ok
  defp normalize_sign_in_result({:ok, _result}), do: :ok
  defp normalize_sign_in_result({:error, _reason} = error), do: error

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _ -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp cast_person_id(person_id) do
    case ID.cast(:person, person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end

  defp normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized_email -> normalized_email
    end
  end

  defp normalize_email(_email), do: nil
end
