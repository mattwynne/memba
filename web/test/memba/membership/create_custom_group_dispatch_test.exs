defmodule Memba.Membership.CreateCustomGroupDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.Events.GroupCreated

  test "create_custom_group/2 carries the authenticated actor into a command routed to Club" do
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    actor_person_id = Memba.ID.generate(:person)

    create_club!(club_id)

    assert %CreateCustomGroup{
             club_id: ^club_id,
             group_id: ^group_id,
             actor_person_id: ^actor_person_id,
             name: " Board "
           } =
             struct!(CreateCustomGroup, %{
               club_id: club_id,
               group_id: group_id,
               actor_person_id: actor_person_id,
               name: " Board "
             })

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^group_id,
                  group_key: nil,
                  name: "Board"
                }
              ]
            }} =
             Membership.create_custom_group(
               %{
                 club_id: club_id,
                 group_id: group_id,
                 actor_person_id: actor_person_id,
                 name: " Board "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %{name: "Board"} = App.aggregate_state(Club, club_id).groups[group_id]
  end

  test "create_custom_group/2 requires an authenticated actor identity" do
    club_id = Memba.ID.generate(:club)

    create_club!(club_id)

    assert {:error, {:missing_required_attribute, :actor_person_id}} =
             Membership.create_custom_group(%{
               club_id: club_id,
               group_id: Memba.ID.generate(:group),
               name: "Board"
             })

    assert {:error, :invalid_actor_person_id} =
             Membership.create_custom_group(%{
               club_id: club_id,
               group_id: Memba.ID.generate(:group),
               actor_person_id: "not-a-person-id",
               name: "Board"
             })
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club"},
               consistency: :strong
             )
  end
end
