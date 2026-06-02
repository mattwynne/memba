defmodule Memba.Membership.Person do
  @moduledoc """
  Person aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated

  @behaviour Aggregate

  defstruct [:person_id, :name, :email, :email_addresses]

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %CreatePerson{} = command) do
    with :ok <- validate_person_id(command.person_id),
         {:ok, name} <- normalize_name(command.name),
         {:ok, email_addresses} <- create_email_addresses(command),
         {:ok, primary_email} <- primary_email(email_addresses) do
      person_created = %PersonCreated{
        person_id: command.person_id,
        name: name,
        email: primary_email
      }

      if is_nil(command.email_addresses) do
        person_created
      else
        [
          person_created,
          %PersonEmailAddressesReplaced{
            person_id: command.person_id,
            email_addresses: email_addresses,
            primary_email: primary_email
          }
        ]
      end
    end
  end

  def execute(%__MODULE__{}, %CreatePerson{}), do: {:error, :already_created}

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %ReplacePersonEmailAddresses{}) do
    {:error, :person_not_created}
  end

  def execute(%__MODULE__{} = person, %ReplacePersonEmailAddresses{} = command) do
    with :ok <- validate_person_id(command.person_id),
         :ok <- validate_matching_person_id(person, command),
         {:ok, email_addresses} <- EmailAddresses.validate_set(command.email_addresses),
         {:ok, primary_email} <- primary_email(email_addresses) do
      %PersonEmailAddressesReplaced{
        person_id: command.person_id,
        email_addresses: email_addresses,
        primary_email: primary_email
      }
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = person, %PersonCreated{} = event) do
    %__MODULE__{
      person
      | person_id: event.person_id,
        name: event.name,
        email: event.email,
        email_addresses: [
          %{email: event.email, normalized_email: event.email, is_primary: true}
        ]
    }
  end

  def apply(%__MODULE__{} = person, %PersonEmailAddressesReplaced{} = event) do
    %__MODULE__{
      person
      | email: event.primary_email,
        email_addresses: event.email_addresses
    }
  end

  defp validate_person_id(person_id) do
    case Ecto.UUID.cast(person_id) do
      {:ok, ^person_id} -> :ok
      _other -> {:error, :invalid_person_id}
    end
  end

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp normalize_name(_name), do: {:error, :invalid_name}

  defp create_email_addresses(%CreatePerson{email_addresses: nil} = command) do
    with {:ok, email} <- EmailAddresses.normalize_primary_email(command.email) do
      {:ok, [%{email: email, normalized_email: email, is_primary: true}]}
    end
  end

  defp create_email_addresses(%CreatePerson{} = command) do
    with {:ok, email_addresses} <- EmailAddresses.validate_set(command.email_addresses),
         :ok <- validate_legacy_email_matches_primary(command.email, email_addresses) do
      {:ok, email_addresses}
    end
  end

  defp validate_legacy_email_matches_primary(nil, _email_addresses), do: :ok

  defp validate_legacy_email_matches_primary(email, email_addresses) do
    with {:ok, email} <- EmailAddresses.normalize_primary_email(email),
         {:ok, primary_email} <- primary_normalized_email(email_addresses) do
      if email == primary_email do
        :ok
      else
        {:error, :primary_email_mismatch}
      end
    end
  end

  defp validate_matching_person_id(
         %__MODULE__{person_id: person_id},
         %ReplacePersonEmailAddresses{
           person_id: person_id
         }
       ) do
    :ok
  end

  defp validate_matching_person_id(%__MODULE__{}, %ReplacePersonEmailAddresses{}) do
    {:error, :invalid_person_id}
  end

  defp primary_email(email_addresses) do
    case Enum.find(email_addresses, & &1.is_primary) do
      %{email: email} -> {:ok, email}
      %{"email" => email} -> {:ok, email}
      _email_address -> {:error, :exactly_one_primary_email_required}
    end
  end

  defp primary_normalized_email(email_addresses) do
    case Enum.find(email_addresses, & &1.is_primary) do
      %{normalized_email: normalized_email} -> {:ok, normalized_email}
      %{"normalized_email" => normalized_email} -> {:ok, normalized_email}
      _email_address -> {:error, :exactly_one_primary_email_required}
    end
  end
end
