defmodule Memba.Membership.MembershipTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Membership

  describe "execute/2 AddMember" do
    test "emits MemberAdded using the caller-supplied UUID identity" do
      membership_id = Memba.ID.generate(:membership)
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)

      command = %AddMember{
        membership_id: membership_id,
        club_id: club_id,
        person_id: person_id
      }

      assert %MemberAdded{
               membership_id: ^membership_id,
               club_id: ^club_id,
               person_id: ^person_id
             } = Membership.execute(%Membership{}, command)
    end

    test "rejects missing or malformed membership UUIDs" do
      assert {:error, :invalid_membership_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: nil,
                 club_id: Memba.ID.generate(:club),
                 person_id: Memba.ID.generate(:person)
               })

      assert {:error, :invalid_membership_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: "not-a-uuid",
                 club_id: Memba.ID.generate(:club),
                 person_id: Memba.ID.generate(:person)
               })
    end

    test "rejects missing or malformed club UUIDs" do
      assert {:error, :invalid_club_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: nil,
                 person_id: Memba.ID.generate(:person)
               })

      assert {:error, :invalid_club_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: "not-a-uuid",
                 person_id: Memba.ID.generate(:person)
               })
    end

    test "rejects missing or malformed person UUIDs" do
      assert {:error, :invalid_person_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: Memba.ID.generate(:club),
                 person_id: nil
               })

      assert {:error, :invalid_person_id} =
               Membership.execute(%Membership{}, %AddMember{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: Memba.ID.generate(:club),
                 person_id: "not-a-uuid"
               })
    end

    test "rejects adding the same membership aggregate twice" do
      membership_id = Memba.ID.generate(:membership)
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)

      membership =
        Membership.apply(%Membership{}, %MemberAdded{
          membership_id: membership_id,
          club_id: club_id,
          person_id: person_id
        })

      assert {:error, :already_added} =
               Membership.execute(membership, %AddMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               })
    end
  end

  describe "execute/2 RemoveMember" do
    test "emits MemberRemoved for an active membership" do
      membership_id = Memba.ID.generate(:membership)
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)

      membership = active_membership(membership_id, club_id, person_id)

      assert %MemberRemoved{
               membership_id: ^membership_id,
               club_id: ^club_id,
               person_id: ^person_id
             } =
               Membership.execute(membership, %RemoveMember{membership_id: membership_id})
    end

    test "rejects removing a membership that has not been added" do
      assert {:error, :not_found} =
               Membership.execute(%Membership{}, %RemoveMember{
                 membership_id: Memba.ID.generate(:membership)
               })
    end

    test "rejects removing a membership twice" do
      membership_id = Memba.ID.generate(:membership)

      membership =
        membership_id
        |> active_membership(Memba.ID.generate(:club), Memba.ID.generate(:person))
        |> Membership.apply(%MemberRemoved{membership_id: membership_id})

      assert {:error, :already_removed} =
               Membership.execute(membership, %RemoveMember{membership_id: membership_id})
    end
  end

  test "apply/2 records the active membership identity, club, and person" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    assert %Membership{
             membership_id: ^membership_id,
             club_id: ^club_id,
             person_id: ^person_id,
             active: true
           } =
             Membership.apply(%Membership{}, %MemberAdded{
               membership_id: membership_id,
               club_id: club_id,
               person_id: person_id
             })
  end

  test "apply/2 records a removed membership as inactive" do
    membership_id = Memba.ID.generate(:membership)

    membership =
      active_membership(membership_id, Memba.ID.generate(:club), Memba.ID.generate(:person))

    assert %Membership{active: false} =
             Membership.apply(membership, %MemberRemoved{membership_id: membership_id})
  end

  defp active_membership(membership_id, club_id, person_id) do
    Membership.apply(%Membership{}, %MemberAdded{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id
    })
  end
end
