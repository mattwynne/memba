defmodule Memba.Membership.ClubTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubUpdated

  describe "execute/2 CreateClub" do
    test "emits ClubCreated using the caller-supplied UUID identity" do
      club_id = Ecto.UUID.generate()

      command = %CreateClub{
        club_id: club_id,
        name: " Kootenay Mountaineering Club ",
        slug: "kmc"
      }

      assert %ClubCreated{
               club_id: ^club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
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

    test "rejects missing club slugs" do
      assert {:error, :invalid_format} =
               Club.execute(%Club{}, %CreateClub{
                 club_id: Ecto.UUID.generate(),
                 name: "Kootenay Mountaineering Club"
               })
    end

    test "rejects creating the same aggregate twice" do
      club_id = Ecto.UUID.generate()

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert {:error, :already_created} =
               Club.execute(club, %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club"
               })
    end
  end

  describe "execute/2 UpdateClub" do
    test "emits ClubUpdated for an existing club" do
      club_id = Ecto.UUID.generate()

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert %ClubUpdated{
               club_id: ^club_id,
               name: "KMC Alpine Club",
               slug: "kmc-alpine"
             } =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: " KMC Alpine Club ",
                 slug: "kmc-alpine"
               })
    end

    test "rejects updating a club that has not been created" do
      assert {:error, :not_created} =
               Club.execute(%Club{}, %UpdateClub{
                 club_id: Ecto.UUID.generate(),
                 name: "KMC Alpine Club",
                 slug: "kmc-alpine"
               })
    end

    test "rejects invalid updated club names and slugs" do
      club_id = Ecto.UUID.generate()

      club =
        Club.apply(%Club{}, %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        })

      assert {:error, :invalid_name} =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: " ",
                 slug: "kmc-alpine"
               })

      assert {:error, :invalid_format} =
               Club.execute(club, %UpdateClub{
                 club_id: club_id,
                 name: "KMC Alpine Club",
                 slug: "KMC Alpine!"
               })
    end
  end

  test "apply/2 records the created club identity and name" do
    club_id = Ecto.UUID.generate()

    assert %Club{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc"
           } =
             Club.apply(%Club{}, %ClubCreated{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             })
  end

  test "apply/2 records updated club name and slug" do
    club_id = Ecto.UUID.generate()

    club =
      Club.apply(%Club{}, %ClubCreated{
        club_id: club_id,
        name: "Kootenay Mountaineering Club",
        slug: "kmc"
      })

    assert %Club{
             club_id: ^club_id,
             name: "KMC Alpine Club",
             slug: "kmc-alpine"
           } =
             Club.apply(club, %ClubUpdated{
               club_id: club_id,
               name: "KMC Alpine Club",
               slug: "kmc-alpine"
             })
  end
end
