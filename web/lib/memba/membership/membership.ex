defmodule Memba.Membership.Membership do
  @moduledoc """
  Membership aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Events.MemberAdded

  @behaviour Aggregate

  defstruct [:membership_id, :club_id, :person_id, active?: false]

  @impl Aggregate
  def execute(%__MODULE__{membership_id: nil}, %AddMember{} = command) do
    with :ok <- validate_uuid(command.membership_id, :invalid_membership_id),
         :ok <- validate_uuid(command.club_id, :invalid_club_id),
         :ok <- validate_uuid(command.person_id, :invalid_person_id) do
      %MemberAdded{
        membership_id: command.membership_id,
        club_id: command.club_id,
        person_id: command.person_id
      }
    end
  end

  def execute(%__MODULE__{}, %AddMember{}), do: {:error, :already_added}

  @impl Aggregate
  def apply(%__MODULE__{} = membership, %MemberAdded{} = event) do
    %__MODULE__{
      membership
      | membership_id: event.membership_id,
        club_id: event.club_id,
        person_id: event.person_id,
        active?: true
    }
  end

  defp validate_uuid(value, error) do
    case Ecto.UUID.cast(value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end
end
