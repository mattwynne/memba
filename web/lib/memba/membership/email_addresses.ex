defmodule Memba.Membership.EmailAddresses do
  @moduledoc """
  Normalization and validation for the set of email addresses attached to a
  Membership person.
  """

  @type normalized_address :: %{
          email: String.t(),
          normalized_email: String.t(),
          is_primary: boolean()
        }

  @type address_state :: %{
          email: String.t(),
          normalized_email: String.t(),
          is_primary: boolean(),
          verified_at: DateTime.t() | nil
        }

  @doc """
  Validate and normalize a replace-all email-address set.

  The returned addresses contain a trimmed display `:email`, a lowercase trimmed
  `:normalized_email`, and the submitted `:is_primary` flag. A valid set has at
  least one address, exactly one primary address, no malformed addresses, and no
  duplicate normalized addresses within the set.
  """
  @spec validate_set(term()) :: {:ok, [normalized_address()]} | {:error, atom()}
  def validate_set(email_addresses) when is_list(email_addresses) do
    with :ok <- require_at_least_one(email_addresses),
         {:ok, email_addresses} <- normalize_entries(email_addresses),
         :ok <- require_exactly_one_primary(email_addresses),
         :ok <- reject_duplicate_normalized_emails(email_addresses) do
      {:ok, email_addresses}
    end
  end

  def validate_set(_email_addresses), do: {:error, :invalid_email_addresses}

  @doc """
  Validate and normalize a single legacy primary email address.
  """
  @spec normalize_primary_email(term()) :: {:ok, String.t()} | {:error, atom()}
  def normalize_primary_email(email) do
    with {:ok, [%{normalized_email: normalized_email}]} <-
           validate_set([%{email: email, is_primary: true}]) do
      {:ok, normalized_email}
    end
  end

  @doc """
  Validate and normalize one email address value.
  """
  @spec normalize_email(term()) ::
          {:ok, %{email: String.t(), normalized_email: String.t()}} | {:error, :invalid_email}
  def normalize_email(email) when is_binary(email) do
    email = String.trim(email)
    normalized_email = String.downcase(email)

    if valid_email?(normalized_email) do
      {:ok, %{email: email, normalized_email: normalized_email}}
    else
      {:error, :invalid_email}
    end
  end

  def normalize_email(_email), do: {:error, :invalid_email}

  @doc """
  Normalize a legacy replace-all email-address set as verified write-side state.

  This preserves the current compatibility meaning of historical create/replace
  events while the member-facing lifecycle moves toward explicit add, verify,
  primary-change, and removal events.
  """
  @spec mark_all_verified(term(), DateTime.t()) :: {:ok, [address_state()]} | {:error, atom()}
  def mark_all_verified(email_addresses, %DateTime{} = verified_at) do
    with {:ok, email_addresses} <- validate_set(email_addresses) do
      {:ok, Enum.map(email_addresses, &Map.put(&1, :verified_at, verified_at))}
    end
  end

  def mark_all_verified(_email_addresses, _verified_at), do: {:error, :invalid_verified_at}

  @doc """
  Add an email address to aggregate state as pending verification.

  Pending addresses are always non-primary. They can become primary only after a
  later explicit verification transition.
  """
  @spec add_pending(term(), term()) :: {:ok, [address_state()]} | {:error, atom()}
  def add_pending(email_addresses, email) do
    with {:ok, email_addresses} <- validate_state_set(email_addresses),
         {:ok, email_address} <- normalize_email(email),
         :ok <- reject_duplicate_normalized_email(email_addresses, email_address.normalized_email) do
      {:ok, email_addresses ++ [Map.merge(email_address, %{is_primary: false, verified_at: nil})]}
    end
  end

  @doc """
  Mark a still-pending email address as verified.
  """
  @spec verify(term(), term(), DateTime.t()) :: {:ok, [address_state()]} | {:error, atom()}
  def verify(email_addresses, email, %DateTime{} = verified_at) do
    with {:ok, email_addresses} <- validate_state_set(email_addresses),
         {:ok, normalized_email} <- normalize_lookup_email(email),
         {:ok, email_address} <- fetch_address(email_addresses, normalized_email),
         :ok <- require_pending(email_address) do
      {:ok,
       update_address(email_addresses, normalized_email, fn email_address ->
         %{email_address | verified_at: verified_at}
       end)}
    end
  end

  def verify(_email_addresses, _email, _verified_at), do: {:error, :invalid_verified_at}

  @doc """
  Make a verified email address primary.
  """
  @spec make_primary(term(), term()) :: {:ok, [address_state()]} | {:error, atom()}
  def make_primary(email_addresses, email) do
    with {:ok, email_addresses} <- validate_state_set(email_addresses),
         {:ok, normalized_email} <- normalize_lookup_email(email),
         {:ok, email_address} <- fetch_address(email_addresses, normalized_email),
         :ok <- require_verified(email_address) do
      {:ok,
       Enum.map(email_addresses, fn email_address ->
         %{email_address | is_primary: email_address.normalized_email == normalized_email}
       end)}
    end
  end

  @doc """
  Remove a non-primary email address from aggregate state.
  """
  @spec remove_non_primary(term(), term()) :: {:ok, [address_state()]} | {:error, atom()}
  def remove_non_primary(email_addresses, email) do
    with {:ok, email_addresses} <- validate_state_set(email_addresses),
         {:ok, normalized_email} <- normalize_lookup_email(email),
         {:ok, email_address} <- fetch_address(email_addresses, normalized_email),
         :ok <- reject_primary_removal(email_address) do
      {:ok,
       Enum.reject(email_addresses, fn email_address ->
         email_address.normalized_email == normalized_email
       end)}
    end
  end

  defp require_at_least_one([]), do: {:error, :email_address_required}
  defp require_at_least_one(_email_addresses), do: :ok

  defp normalize_entries(email_addresses) do
    email_addresses
    |> Enum.reduce_while({:ok, []}, fn email_address, {:ok, normalized_email_addresses} ->
      case normalize_entry(email_address) do
        {:ok, normalized_email_address} ->
          {:cont, {:ok, [normalized_email_address | normalized_email_addresses]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized_email_addresses} -> {:ok, Enum.reverse(normalized_email_addresses)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_entry(email_address) when is_map(email_address) do
    with {:ok, email} <- fetch_email(email_address),
         {:ok, is_primary} <- fetch_primary(email_address),
         {:ok, normalized_email} <- normalize_email(email) do
      {:ok, Map.put(normalized_email, :is_primary, is_primary)}
    end
  end

  defp normalize_entry(_email_address), do: {:error, :invalid_email_address}

  defp fetch_email(%{email: email}), do: {:ok, email}
  defp fetch_email(%{"email" => email}), do: {:ok, email}
  defp fetch_email(_email_address), do: {:error, :invalid_email}

  defp fetch_primary(%{is_primary: is_primary}), do: cast_primary(is_primary)
  defp fetch_primary(%{"is_primary" => is_primary}), do: cast_primary(is_primary)
  defp fetch_primary(_email_address), do: {:ok, false}

  defp cast_primary(is_primary) when is_boolean(is_primary), do: {:ok, is_primary}
  defp cast_primary("true"), do: {:ok, true}
  defp cast_primary("false"), do: {:ok, false}
  defp cast_primary(_is_primary), do: {:error, :invalid_primary_email}

  defp require_exactly_one_primary(email_addresses) do
    primary_count = Enum.count(email_addresses, & &1.is_primary)

    if primary_count == 1 do
      :ok
    else
      {:error, :exactly_one_primary_email_required}
    end
  end

  defp reject_duplicate_normalized_emails(email_addresses) do
    normalized_emails = Enum.map(email_addresses, & &1.normalized_email)

    if Enum.uniq(normalized_emails) == normalized_emails do
      :ok
    else
      {:error, :duplicate_email_address}
    end
  end

  defp reject_duplicate_normalized_email(email_addresses, normalized_email) do
    if Enum.any?(email_addresses, &(&1.normalized_email == normalized_email)) do
      {:error, :duplicate_email_address}
    else
      :ok
    end
  end

  defp validate_state_set(email_addresses) when is_list(email_addresses) do
    with :ok <- require_at_least_one(email_addresses),
         {:ok, email_addresses} <- normalize_state_entries(email_addresses),
         :ok <- require_exactly_one_primary(email_addresses),
         :ok <- reject_duplicate_normalized_emails(email_addresses),
         :ok <- require_primary_verified(email_addresses) do
      {:ok, email_addresses}
    end
  end

  defp validate_state_set(_email_addresses), do: {:error, :invalid_email_addresses}

  defp normalize_state_entries(email_addresses) do
    email_addresses
    |> Enum.reduce_while({:ok, []}, fn email_address, {:ok, normalized_email_addresses} ->
      case normalize_state_entry(email_address) do
        {:ok, normalized_email_address} ->
          {:cont, {:ok, [normalized_email_address | normalized_email_addresses]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized_email_addresses} -> {:ok, Enum.reverse(normalized_email_addresses)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_state_entry(email_address) when is_map(email_address) do
    with {:ok, normalized_email_address} <- normalize_entry(email_address),
         {:ok, verified_at} <- fetch_verified_at(email_address) do
      {:ok, Map.put(normalized_email_address, :verified_at, verified_at)}
    end
  end

  defp normalize_state_entry(_email_address), do: {:error, :invalid_email_address}

  defp fetch_verified_at(%{verified_at: verified_at}), do: cast_verified_at(verified_at)
  defp fetch_verified_at(%{"verified_at" => verified_at}), do: cast_verified_at(verified_at)
  defp fetch_verified_at(_email_address), do: {:error, :invalid_verified_at}

  defp cast_verified_at(nil), do: {:ok, nil}
  defp cast_verified_at(%DateTime{} = verified_at), do: {:ok, verified_at}
  defp cast_verified_at(_verified_at), do: {:error, :invalid_verified_at}

  defp require_primary_verified(email_addresses) do
    case Enum.find(email_addresses, & &1.is_primary) do
      %{verified_at: %DateTime{}} -> :ok
      %{verified_at: nil} -> {:error, :primary_email_address_not_verified}
    end
  end

  defp normalize_lookup_email(email) do
    with {:ok, %{normalized_email: normalized_email}} <- normalize_email(email) do
      {:ok, normalized_email}
    end
  end

  defp fetch_address(email_addresses, normalized_email) do
    case Enum.find(email_addresses, &(&1.normalized_email == normalized_email)) do
      nil -> {:error, :email_address_not_found}
      email_address -> {:ok, email_address}
    end
  end

  defp require_pending(%{verified_at: nil}), do: :ok
  defp require_pending(%{verified_at: %DateTime{}}), do: {:error, :email_address_already_verified}

  defp require_verified(%{verified_at: %DateTime{}}), do: :ok
  defp require_verified(%{verified_at: nil}), do: {:error, :email_address_not_verified}

  defp reject_primary_removal(%{is_primary: true}),
    do: {:error, :primary_email_address_cannot_be_removed}

  defp reject_primary_removal(%{is_primary: false}), do: :ok

  defp update_address(email_addresses, normalized_email, update_fun) do
    Enum.map(email_addresses, fn email_address ->
      if email_address.normalized_email == normalized_email do
        update_fun.(email_address)
      else
        email_address
      end
    end)
  end

  defp valid_email?(email) do
    Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email)
  end
end
