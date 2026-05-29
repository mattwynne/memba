defmodule Memba.Membership.Person do
  @moduledoc """
  Person aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Events.PersonCreated

  @behaviour Aggregate

  defstruct [:person_id, :name, :email]

  @impl Aggregate
  def execute(%__MODULE__{person_id: nil}, %CreatePerson{} = command) do
    with :ok <- validate_person_id(command.person_id),
         {:ok, name} <- normalize_name(command.name),
         {:ok, email} <- normalize_email(command.email) do
      %PersonCreated{person_id: command.person_id, name: name, email: email}
    end
  end

  def execute(%__MODULE__{}, %CreatePerson{}), do: {:error, :already_created}

  @impl Aggregate
  def apply(%__MODULE__{} = person, %PersonCreated{} = event) do
    %__MODULE__{person | person_id: event.person_id, name: event.name, email: event.email}
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

  defp normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if valid_email?(email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  defp normalize_email(_email), do: {:error, :invalid_email}

  defp valid_email?(email) do
    case String.split(email, "@") do
      [local, domain] -> local != "" and domain != "" and String.contains?(domain, ".")
      _other -> false
    end
  end
end
