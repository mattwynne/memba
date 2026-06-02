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

  defp valid_email?(email) do
    Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email)
  end
end
