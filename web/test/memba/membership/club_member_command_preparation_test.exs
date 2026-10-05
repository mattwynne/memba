defmodule Memba.Membership.ClubMemberCommandPreparationTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Membership.ClubMember.{Remove, Role}
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Policies.SystemGroupMembership

  test "explicit removal identities preserve Club routing without consulting projections" do
    attrs = %{
      "club_id" => ID.generate(:club),
      "person_id" => ID.generate(:person),
      "membership_id" => ID.generate(:membership)
    }

    assert {:ok, %RemoveClubMember{} = command} = Remove.prepare(attrs)
    assert command.club_id == attrs["club_id"]
    assert command.person_id == attrs["person_id"]
    assert command.membership_id == attrs["membership_id"]
  end

  test "partial routing identity and absent role fields retain public errors" do
    assert {:error, {:missing_required_attribute, :club_id}} =
             Remove.prepare(%{
               membership_id: ID.generate(:membership),
               person_id: ID.generate(:person)
             })

    assert {:error, {:missing_required_attribute, :person_id}} =
             Remove.prepare(%{
               membership_id: ID.generate(:membership),
               club_id: ID.generate(:club)
             })

    assert {:error, {:missing_required_attribute, :membership_id}} = Remove.prepare(%{})

    assert {:error, {:missing_required_attribute, :membership_id}} =
             Role.prepare_assign(%{club_id: ID.generate(:club)})

    assert {:error, :invalid_club_id} = Role.prepare_remove_administrator(%{club_id: "bad"})
  end

  test "dispatch consistency always waits for system-group policy unless strong already waits for all" do
    assert [consistency: [SystemGroupMembership]] =
             CommandDispatch.system_group_membership_consistency([])

    assert [consistency: :strong] =
             CommandDispatch.system_group_membership_consistency(consistency: :strong)

    assert [consistency: [SystemGroupMembership, :other]] =
             CommandDispatch.system_group_membership_consistency(consistency: [:other])

    assert [consistency: [SystemGroupMembership]] =
             CommandDispatch.system_group_membership_consistency(
               consistency: [SystemGroupMembership]
             )
  end
end
