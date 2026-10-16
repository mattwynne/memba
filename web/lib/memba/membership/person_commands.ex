defmodule Memba.Membership.PersonCommands do
  @moduledoc """
  Prepare CreatePerson commands without dispatching them. The projected email
  ownership check is a preflight; the Person aggregate still validates creation.
  """

  alias Memba.Membership.Commands.ChangePersonName
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.PersonEmailAddressCommands

  def prepare_create(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, email_attrs} <- create_email_attrs(attrs) do
      command = struct!(CreatePerson, Map.merge(%{person_id: person_id, name: name}, email_attrs))

      with {:ok, email_addresses} <- normalize_email_addresses(command),
           :ok <- PersonEmailAddressCommands.prevent_duplicate(person_id, email_addresses) do
        {:ok, command}
      end
    end
  end

  def prepare_change_name(attrs) when is_map(attrs) do
    with {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, actor_person_id} <- fetch_required(attrs, :actor_person_id),
         :ok <- validate_self_authority(person_id, actor_person_id),
         {:ok, expected_name} <- fetch_required(attrs, :expected_name),
         {:ok, name} <- fetch_required(attrs, :name) do
      {:ok,
       %ChangePersonName{
         person_id: person_id,
         actor_person_id: actor_person_id,
         expected_name: expected_name,
         name: name
       }}
    end
  end

  defp normalize_email_addresses(%CreatePerson{email_addresses: nil, email: email}) do
    with {:ok, normalized_email} <- EmailAddresses.normalize_primary_email(email) do
      {:ok, [%{normalized_email: normalized_email}]}
    end
  end

  defp normalize_email_addresses(%CreatePerson{email_addresses: email_addresses}) do
    EmailAddresses.validate_set(email_addresses)
  end

  defp create_email_attrs(attrs) do
    case fetch_optional(attrs, :email_addresses) do
      {:ok, email_addresses} ->
        email_attrs =
          case fetch_optional(attrs, :email) do
            {:ok, email} -> %{email: email, email_addresses: email_addresses}
            :error -> %{email_addresses: email_addresses}
          end

        {:ok, email_attrs}

      :error ->
        with {:ok, email} <- fetch_required(attrs, :email) do
          {:ok, %{email: email}}
        end
    end
  end

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp validate_self_authority(person_id, person_id), do: :ok

  defp validate_self_authority(_person_id, _actor_person_id) do
    {:error, :self_authorization_required}
  end

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _ -> :error
    end
  end
end
