defmodule Memba.Membership.PersonCommands do
  @moduledoc """
  Prepares Person commands without dispatching them.

  Creation includes a projected email ownership preflight; the Person aggregate
  still validates creation. Self-service rename preparation authorizes the
  trusted actor to target their own Person before constructing the command.
  """

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

  @doc """
  Prepares a self-service rename using trusted actor context separately from
  the target Person identity, server-held expected name, and editable
  attributes.
  """
  def prepare_rename(
        %{person_id: actor_person_id},
        target_person_id,
        expected_name,
        editable_attrs
      )
      when is_map(editable_attrs) do
    with :ok <- validate_actor_person_id(actor_person_id),
         :ok <- authorize_self(actor_person_id, target_person_id),
         {:ok, name} <- fetch_required(editable_attrs, :name) do
      {:ok,
       %RenamePerson{
         person_id: target_person_id,
         name: name,
         expected_name: expected_name
       }}
    end
  end

  def prepare_rename(_actor_context, _target_person_id, _expected_name, _editable_attrs),
    do: {:error, :unauthorized}

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

  defp validate_actor_person_id(person_id) do
    case Memba.ID.cast(:person, person_id) do
      {:ok, ^person_id} -> :ok
      _other -> {:error, :unauthorized}
    end
  end

  defp authorize_self(person_id, person_id), do: :ok
  defp authorize_self(_actor_person_id, _target_person_id), do: {:error, :unauthorized}

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
