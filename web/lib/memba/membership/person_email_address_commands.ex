defmodule Memba.Membership.PersonEmailAddressCommands do
  @moduledoc """
  Prepare person email-address transitions. Projection checks are advisory; the
  Person aggregate remains the authority for verification and primary state.

  Replacement/removal return pending verification requests alongside the
  command. Their caller must revoke those tokens only after successful dispatch.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Repo

  alias Memba.Membership.Commands.{
    AddPersonEmailAddress,
    ReplacePersonEmailAddresses,
    VerifyPersonEmailAddress,
    MakePersonEmailAddressPrimary,
    RemovePersonEmailAddress
  }

  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Projections.PersonEmailAddress

  def prepare_add(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, normalized} <- EmailAddresses.normalize_email(email),
         :ok <- prevent_duplicate(person_id, [normalized]) do
      {:ok, %AddPersonEmailAddress{person_id: person_id, email: email}}
    end
  end

  def prepare_replace(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email_addresses} <- fetch_required(attrs, :email_addresses),
         {:ok, normalized} <- EmailAddresses.validate_set(email_addresses),
         :ok <- prevent_duplicate(person_id, normalized),
         {:ok, requests} <- pending_removed_requests(person_id, normalized) do
      {:ok, %ReplacePersonEmailAddresses{person_id: person_id, email_addresses: email_addresses},
       requests}
    end
  end

  def prepare_verify(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email),
         {:ok, verified_at} <- verified_at(attrs) do
      {:ok,
       %VerifyPersonEmailAddress{person_id: person_id, email: email, verified_at: verified_at}}
    end
  end

  def prepare_make_primary(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email) do
      {:ok, %MakePersonEmailAddressPrimary{person_id: person_id, email: email}}
    end
  end

  def prepare_remove(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, email} <- fetch_required(attrs, :email) do
      command = %RemovePersonEmailAddress{person_id: person_id, email: email}
      {:ok, command, pending_removed_requests(person_id, email)}
    end
  end

  # Also used by person creation, which remains in the Membership facade.
  def prevent_duplicate(person_id, email_addresses) do
    with {:ok, person_id} <- cast_person_id(person_id) do
      normalized_emails = Enum.map(email_addresses, & &1.normalized_email)

      PersonEmailAddress
      |> where([address], address.normalized_email in ^normalized_emails)
      |> where([address], address.person_id != ^person_id)
      |> select([address], address.normalized_email)
      |> limit(1)
      |> Repo.one()
      |> case do
        nil -> :ok
        _email -> {:error, :email_address_taken}
      end
    end
  end

  defp pending_removed_requests(person_id, replacement) when is_list(replacement) do
    with {:ok, person_id} <- cast_person_id(person_id) do
      retained = Enum.map(replacement, & &1.normalized_email)

      requests =
        PersonEmailAddress
        |> where([address], address.person_id == ^person_id)
        |> where([address], is_nil(address.verified_at))
        |> where([address], address.normalized_email not in ^retained)
        |> order_by([address], asc: address.normalized_email)
        |> Repo.all()
        |> Enum.map(&verification_request/1)

      {:ok, requests}
    end
  end

  defp pending_removed_requests(person_id, email) do
    with {:ok, person_id} <- cast_person_id(person_id),
         {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email) do
      PersonEmailAddress
      |> where([address], address.person_id == ^person_id)
      |> where([address], address.normalized_email == ^normalized_email)
      |> where([address], is_nil(address.verified_at))
      |> Repo.one()
      |> case do
        nil -> []
        address -> [verification_request(address)]
      end
    else
      _invalid -> []
    end
  end

  defp verification_request(address) do
    %{
      person_id: address.person_id,
      email: address.email,
      normalized_email: address.normalized_email
    }
  end

  defp cast_person_id(id) do
    case ID.cast(:person, id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _ -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp verified_at(attrs) do
    case attrs do
      %{verified_at: %DateTime{} = value} -> {:ok, value}
      %{"verified_at" => %DateTime{} = value} -> {:ok, value}
      %{verified_at: _} -> {:error, :invalid_verified_at}
      %{"verified_at" => _} -> {:error, :invalid_verified_at}
      _ -> {:ok, DateTime.utc_now(:microsecond)}
    end
  end
end
