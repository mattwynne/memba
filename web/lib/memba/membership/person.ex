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
         {:ok, name} <- normalize_string(command.name, :invalid_name),
         {:ok, email} <- normalize_string(command.email, :invalid_email) do
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

  defp normalize_string(value, error) when is_binary(value) do
    case String.trim(value) do
      "" -> {:error, error}
      trimmed_value -> {:ok, trimmed_value}
    end
  end

  defp normalize_string(_value, error), do: {:error, error}
end
