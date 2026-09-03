defmodule Memba.Membership.Membership do
  @moduledoc """
  Membership aggregate for the Membership bounded context.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved

  @behaviour Aggregate

  defstruct [:membership_id, :club_id, :person_id, active: false]

  @impl Aggregate
  def execute(%__MODULE__{membership_id: nil}, %AddMember{} = command) do
    with :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id) do
      %MemberAdded{
        membership_id: command.membership_id,
        club_id: command.club_id,
        person_id: command.person_id
      }
    end
  end

  def execute(%__MODULE__{}, %AddMember{}), do: {:error, :already_added}

  def execute(%__MODULE__{membership_id: nil}, %RemoveMember{}), do: {:error, :not_found}

  def execute(%__MODULE__{active: false}, %RemoveMember{}), do: {:error, :already_removed}

  def execute(%__MODULE__{} = membership, %RemoveMember{} = command) do
    with :ok <- validate_id(:membership, command.membership_id, :invalid_membership_id),
         :ok <- validate_same_membership(membership.membership_id, command.membership_id) do
      %MemberRemoved{
        membership_id: command.membership_id,
        club_id: membership.club_id,
        person_id: membership.person_id
      }
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = membership, %MemberAdded{} = event) do
    %__MODULE__{
      membership
      | membership_id: event.membership_id,
        club_id: event.club_id,
        person_id: event.person_id,
        active: true
    }
  end

  def apply(%__MODULE__{} = membership, %MemberRemoved{}) do
    %__MODULE__{membership | active: false}
  end

  defp validate_same_membership(membership_id, membership_id), do: :ok

  defp validate_same_membership(_membership_id, _command_membership_id),
    do: {:error, :membership_id_mismatch}

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end
end
