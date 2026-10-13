defmodule Memba.Membership.PersonMergeTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.PersonMerge
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Repo

  test "preview is non-mutating and returns a safe public receipt" do
    %{source_id: source_id, target_id: target_id} = people_with_overlapping_membership()

    assert {:ok, %{status: :ready} = receipt} = PersonMerge.preview(source_id, target_id)
    refute Map.has_key?(receipt, :command)
    assert %{person_id: ^source_id} = PersonQueries.get_person_by_email("source@example.com")
  end

  test "preview rejects an active source role assignment" do
    %{source_id: source_id, target_id: target_id, source_membership_id: membership_id} =
      people_with_overlapping_membership()

    Repo.insert!(%RoleAssignment{
      club_id: Memba.ID.generate(:club),
      membership_id: membership_id,
      person_id: source_id,
      role_id: Memba.ID.generate(:role),
      active: true
    })

    assert {:error, :source_has_active_role_assignments} =
             PersonMerge.preview(source_id, target_id)
  end

  test "preview rejects an active source custom-group membership" do
    %{
      source_id: source_id,
      target_id: target_id,
      club_id: club_id,
      source_membership_id: membership_id
    } = people_with_overlapping_membership()

    Repo.insert!(%GroupMembership{
      club_id: club_id,
      group_id: Memba.ID.generate(:group),
      membership_id: membership_id,
      person_id: source_id,
      active: true
    })

    assert {:error, :source_has_active_custom_group_memberships} =
             PersonMerge.preview(source_id, target_id)
  end

  defp people_with_overlapping_membership do
    source_id = create_person("Source", "source@example.com")
    target_id = create_person("Target", "target@example.com")
    club_id = Memba.ID.generate(:club)
    source_membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%Membership{
      membership_id: source_membership_id,
      club_id: club_id,
      person_id: source_id,
      active: true
    })

    Repo.insert!(%Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club_id,
      person_id: target_id,
      active: true
    })

    %{
      source_id: source_id,
      target_id: target_id,
      club_id: club_id,
      source_membership_id: source_membership_id
    }
  end

  defp create_person(name, email) do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: person_id, name: name, email: email},
               consistency: :strong
             )

    person_id
  end
end
