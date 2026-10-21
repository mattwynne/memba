defmodule Memba.Membership.PersonCommands do
  @moduledoc """
  Prepare Person commands without dispatching them. Projected checks are
  preflights; the Person aggregate still validates its invariants.
  """

  alias Memba.ID
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RenamePerson
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

  def prepare_rename(actor, attrs) when is_map(attrs) do
    with {:ok, person_id} <- actor_person_id(actor),
         :ok <- authorize_rename_target(attrs, person_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, expected_name} <- fetch_required(attrs, :expected_name) do
      {:ok,
       %RenamePerson{
         person_id: person_id,
         name: name,
         expected_name: expected_name
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

  defp actor_person_id(actor) when is_map(actor) do
    with {:ok, person_id} <- fetch_optional(actor, :person_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      {:ok, person_id}
    else
      _error -> {:error, :unauthorized}
    end
  end

  defp actor_person_id(_actor), do: {:error, :unauthorized}

  defp authorize_rename_target(attrs, actor_person_id) do
    case fetch_optional(attrs, :person_id) do
      :error -> :ok
      {:ok, ^actor_person_id} -> :ok
      {:ok, _other_person_id} -> {:error, :unauthorized}
    end
  end

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
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
