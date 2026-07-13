defmodule Memba.Membership.Person do
  @moduledoc """
  Person aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.VerifyPersonEmailAddress
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged

  @behaviour Aggregate
  @legacy_verified_at ~U[1970-01-01 00:00:00Z]

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
         {:ok, email_addresses} <-
           EmailAddresses.replace_preserving_verification_state(
             person.email_addresses,
             command.email_addresses
           ),
         {:ok, primary_email} <- primary_email(email_addresses) do
      %PersonEmailAddressesReplaced{
        person_id: command.person_id,
        email_addresses: email_addresses,
        primary_email: primary_email
      }
    end
  end

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %AddPersonEmailAddress{}) do
    {:error, :person_not_created}
  end

  def execute(%__MODULE__{} = person, %AddPersonEmailAddress{} = command) do
    with :ok <- validate_person_id(command.person_id),
         :ok <- validate_matching_person_id(person, command),
         {:ok, email_addresses} <-
           EmailAddresses.add_pending(person.email_addresses, command.email),
         {:ok, email_address} <- find_address(email_addresses, command.email) do
      %PersonEmailAddressAdded{
        person_id: command.person_id,
        email: email_address.email,
        normalized_email: email_address.normalized_email
      }
    end
  end

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %VerifyPersonEmailAddress{}) do
    {:error, :person_not_created}
  end

  def execute(%__MODULE__{} = person, %VerifyPersonEmailAddress{} = command) do
    with :ok <- validate_person_id(command.person_id),
         :ok <- validate_matching_person_id(person, command),
         :ok <- validate_verified_at(command.verified_at),
         {:ok, email_addresses} <-
           EmailAddresses.verify(person.email_addresses, command.email, command.verified_at),
         {:ok, email_address} <- find_address(email_addresses, command.email) do
      %PersonEmailAddressVerified{
        person_id: command.person_id,
        email: email_address.email,
        normalized_email: email_address.normalized_email,
        verified_at: command.verified_at
      }
    end
  end

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %MakePersonEmailAddressPrimary{}) do
    {:error, :person_not_created}
  end

  def execute(%__MODULE__{} = person, %MakePersonEmailAddressPrimary{} = command) do
    with :ok <- validate_person_id(command.person_id),
         :ok <- validate_matching_person_id(person, command),
         {:ok, email_addresses} <-
           EmailAddresses.make_primary(person.email_addresses, command.email),
         {:ok, email_address} <- primary_address(email_addresses) do
      %PersonPrimaryEmailAddressChanged{
        person_id: command.person_id,
        primary_email: email_address.email,
        normalized_email: email_address.normalized_email
      }
    end
  end

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %RemovePersonEmailAddress{}) do
    {:error, :person_not_created}
  end

  def execute(%__MODULE__{} = person, %RemovePersonEmailAddress{} = command) do
    with :ok <- validate_person_id(command.person_id),
         :ok <- validate_matching_person_id(person, command),
         {:ok, email_address} <- find_address(person.email_addresses, command.email),
         {:ok, _email_addresses} <-
           EmailAddresses.remove_non_primary(person.email_addresses, command.email) do
      %PersonEmailAddressRemoved{
        person_id: command.person_id,
        email: email_address.email,
        normalized_email: email_address.normalized_email
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
        email_addresses:
          mark_all_verified!([
            %{email: event.email, is_primary: true}
          ])
    }
  end

  def apply(%__MODULE__{} = person, %PersonEmailAddressesReplaced{} = event) do
    %__MODULE__{
      person
      | email: event.primary_email,
        email_addresses: replacement_email_addresses!(event.email_addresses)
    }
  end

  def apply(%__MODULE__{} = person, %PersonEmailAddressAdded{} = event) do
    %__MODULE__{
      person
      | email_addresses:
          add_pending!(person.email_addresses, %{
            email: event.email,
            normalized_email: event.normalized_email
          })
    }
  end

  def apply(%__MODULE__{} = person, %PersonEmailAddressVerified{} = event) do
    %__MODULE__{
      person
      | email_addresses:
          verify!(person.email_addresses, event.normalized_email, verified_at!(event.verified_at))
    }
  end

  def apply(%__MODULE__{} = person, %PersonPrimaryEmailAddressChanged{} = event) do
    %__MODULE__{
      person
      | email: event.primary_email,
        email_addresses: make_primary!(person.email_addresses, event.normalized_email)
    }
  end

  def apply(%__MODULE__{} = person, %PersonEmailAddressRemoved{} = event) do
    %__MODULE__{
      person
      | email_addresses: remove_non_primary!(person.email_addresses, event.normalized_email)
    }
  end

  defp validate_person_id(person_id) do
    case ID.cast(:person, person_id) do
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

  defp validate_matching_person_id(%__MODULE__{person_id: person_id}, %{person_id: person_id}) do
    :ok
  end

  defp validate_matching_person_id(%__MODULE__{}, %{person_id: _person_id}) do
    {:error, :invalid_person_id}
  end

  defp validate_verified_at(%DateTime{}), do: :ok
  defp validate_verified_at(_verified_at), do: {:error, :invalid_verified_at}

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

  defp primary_address(email_addresses) do
    case Enum.find(email_addresses, & &1.is_primary) do
      %{email: _email, normalized_email: _normalized_email} = email_address ->
        {:ok, email_address}

      _email_address ->
        {:error, :exactly_one_primary_email_required}
    end
  end

  defp find_address(email_addresses, email) do
    with {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email) do
      case Enum.find(email_addresses, &(&1.normalized_email == normalized_email)) do
        nil -> {:error, :email_address_not_found}
        email_address -> {:ok, email_address}
      end
    end
  end

  defp mark_all_verified!(email_addresses) do
    case EmailAddresses.mark_all_verified(email_addresses, @legacy_verified_at) do
      {:ok, email_addresses} -> email_addresses
      {:error, _reason} -> email_addresses
    end
  end

  defp replacement_email_addresses!(email_addresses) do
    if Enum.all?(email_addresses, &has_verified_at?/1) do
      case EmailAddresses.validate_state(email_addresses) do
        {:ok, email_addresses} -> email_addresses
        {:error, _reason} -> email_addresses
      end
    else
      mark_all_verified!(email_addresses)
    end
  end

  defp has_verified_at?(%{verified_at: _verified_at}), do: true
  defp has_verified_at?(%{"verified_at" => _verified_at}), do: true
  defp has_verified_at?(_email_address), do: false

  defp add_pending!(email_addresses, %{email: email}) do
    case EmailAddresses.add_pending(email_addresses, email) do
      {:ok, email_addresses} -> email_addresses
      {:error, _reason} -> email_addresses
    end
  end

  defp verify!(email_addresses, normalized_email, verified_at) do
    case EmailAddresses.verify(email_addresses, normalized_email, verified_at) do
      {:ok, email_addresses} -> email_addresses
      {:error, _reason} -> email_addresses
    end
  end

  defp make_primary!(email_addresses, normalized_email) do
    case EmailAddresses.make_primary(email_addresses, normalized_email) do
      {:ok, email_addresses} -> email_addresses
      {:error, _reason} -> email_addresses
    end
  end

  defp remove_non_primary!(email_addresses, normalized_email) do
    case EmailAddresses.remove_non_primary(email_addresses, normalized_email) do
      {:ok, email_addresses} -> email_addresses
      {:error, _reason} -> email_addresses
    end
  end

  defp verified_at!(%DateTime{} = verified_at), do: verified_at

  defp verified_at!(verified_at) when is_binary(verified_at) do
    case DateTime.from_iso8601(verified_at) do
      {:ok, verified_at, _offset} -> verified_at
      {:error, _reason} -> @legacy_verified_at
    end
  end
end
