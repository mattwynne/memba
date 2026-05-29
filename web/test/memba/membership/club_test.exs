defmodule Memba.Membership.ClubTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Events.ClubCreated

  describe "execute/2 CreateClub" do
    test "emits ClubCreated using the caller-supplied UUID identity" do
      club_id = Ecto.UUID.generate()

      command = %CreateClub{
        club_id: club_id,
        name: " Kootenay Mountaineering Club "
      }

      assert %ClubCreated{
               club_id: ^club_id,
               name: "Kootenay Mountaineering Club"
             } = Club.execute(%Club{}, command)
    end

    test "rejects missing or malformed club UUIDs" do
      assert {:error, :invalid_club_id} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: nil,
                 name: "Kootenay Mountaineering Club"
               })

      assert {:error, :invalid_club_id} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: "not-a-uuid",
                 name: "Kootenay Mountaineering Club"
               })
    end

    test "rejects blank club names" do
      assert {:error, :invalid_name} =
               Club.execute(%Club{}, %CreateClub{club_id: Ecto.UUID.generate(), name: "  "})
    end

    test "rejects creating the same aggregate twice" do
      club_id = Ecto.UUID.generate()

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club"
        })

      assert {:error, :already_created} =
               Club.execute(club, %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club"
               })
    end
  end

  test "apply/2 records the created club identity and name" do
    club_id = Ecto.UUID.generate()

    assert %Club{club_id: ^club_id, name: "Kootenay Mountaineering Club"} =
             Club.apply(%Club{}, %ClubCreated{
               club_id: club_id,
               name: "Kootenay Mountaineering Club"
             })
  end
end
