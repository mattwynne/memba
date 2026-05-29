defmodule Memba.Membership.Club do
  @moduledoc """
  Club aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Events.ClubCreated

  @behaviour Aggregate

  defstruct [:club_id, :name]

  @impl Aggregate
  def execute(%__MODULE__{club_id: nil}, %CreateClub{} = command) do
    with :ok <- validate_club_id(command.club_id),
         {:ok, name} <- normalize_name(command.name) do
      %ClubCreated{club_id: command.club_id, name: name}
    end
  end

  def execute(%__MODULE__{}, %CreateClub{}), do: {:error, :already_created}

  @impl Aggregate
  def apply(%__MODULE__{} = club, %ClubCreated{} = event) do
    %__MODULE__{club | club_id: event.club_id, name: event.name}
  end

  defp validate_club_id(club_id) do
    case Ecto.UUID.cast(club_id) do
      {:ok, ^club_id} -> :ok
      _other -> {:error, :invalid_club_id}
    end
  end

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp normalize_name(_name), do: {:error, :invalid_name}
end
