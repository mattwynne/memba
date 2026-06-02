defmodule Memba.Membership.Club do
  @moduledoc """
  Club aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Slug

  @behaviour Aggregate

  defstruct [:club_id, :name, :slug]

  @impl Aggregate
  def execute(%__MODULE__{club_id: nil}, %CreateClub{} = command) do
    with :ok <- validate_club_id(command.club_id),
         {:ok, name} <- normalize_name(command.name),
         {:ok, slug} <- Slug.validate(command.slug) do
      %ClubCreated{club_id: command.club_id, name: name, slug: slug}
    end
  end

  def execute(%__MODULE__{}, %CreateClub{}), do: {:error, :already_created}

  def execute(%__MODULE__{club_id: nil}, %UpdateClub{}), do: {:error, :not_created}

  def execute(%__MODULE__{} = club, %UpdateClub{} = command) do
    with :ok <- validate_existing_club_id(club, command.club_id),
         {:ok, name} <- normalize_name(command.name),
         {:ok, slug} <- Slug.validate(command.slug) do
      %ClubUpdated{club_id: command.club_id, name: name, slug: slug}
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = club, %ClubCreated{} = event) do
    %__MODULE__{club | club_id: event.club_id, name: event.name, slug: event.slug}
  end

  def apply(%__MODULE__{} = club, %ClubUpdated{} = event) do
    %__MODULE__{club | name: event.name, slug: event.slug}
  end

  defp validate_club_id(club_id) do
    case Ecto.UUID.cast(club_id) do
      {:ok, ^club_id} -> :ok
      _other -> {:error, :invalid_club_id}
    end
  end

  defp validate_existing_club_id(%__MODULE__{club_id: club_id}, club_id), do: :ok
  defp validate_existing_club_id(%__MODULE__{}, _club_id), do: {:error, :invalid_club_id}

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp normalize_name(_name), do: {:error, :invalid_name}
end
