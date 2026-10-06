defmodule MembaWeb.MemberGroupCreationQueryTest do
  use Memba.DataCase, async: false

  alias LiveQuery.Query
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias MembaWeb.MemberGroupCreationQuery

  test "describes and loads one coherent group-creation context with exact interests" do
    member = create_authorized_member()
    query = MemberGroupCreationQuery.query()

    assert query.id == :member_group_creation
    assert query.assign == :group_creation_context

    assert {:ok, context, interests} =
             Query.load(query, %{
               club_id: member.club_id,
               authenticated_email: "  MEMBER@EXAMPLE.COM "
             })

    assert Map.keys(context) |> Enum.sort() == [:current_member, :selected_club]
    assert context.selected_club.club_id == member.club_id
    assert context.current_member.id == member.person_id
    assert context.current_member.membership_id == member.membership_id

    expected_interests = [
      {:club, member.club_id},
      {:membership, member.membership_id},
      {:person, member.person_id},
      {:person_club, member.club_id, member.person_id},
      {:person_clubs, member.person_id},
      {:member_roles, member.club_id, member.membership_id, member.person_id},
      {:member_permissions, member.club_id, member.membership_id, member.person_id},
      {:club_roles, member.club_id},
      {:club_permissions, member.club_id}
    ]

    assert MapSet.new(interests) == MapSet.new(expected_interests)
    assert length(interests) == 9

    refute Map.has_key?(context, :group_id)
    refute Map.has_key?(context, :form)
    refute Map.has_key?(context, :name)
    refute Map.has_key?(context, :preview)
    refute Map.has_key?(context, :errors)
    refute Map.has_key?(context, :retry_key)
    refute Map.has_key?(context, :command)

    excluded_interest_names = [
      :club_members,
      :club_groups,
      :group,
      :group_members,
      :group_participation,
      :conversation,
      :message,
      :delivery
    ]

    refute Enum.any?(interests, fn interest ->
             elem(interest, 0) in excluded_interest_names
           end)
  end

  test "resolves attached-email authentication to membership by Person ID" do
    member = create_authorized_member()

    insert_membership_person_email_address!(
      person_id: member.person_id,
      email: "member.attached@example.com",
      is_primary: false
    )

    assert {:ok, context} =
             MemberGroupCreationQuery.load(
               member.club_id,
               " MEMBER.ATTACHED@EXAMPLE.COM "
             )

    assert context.current_member.id == member.person_id
    assert context.current_member.email == "member@example.com"
  end

  test "freshly rejects a deactivated selected-club membership" do
    member = create_authorized_member()

    assert {:ok, _context} =
             MemberGroupCreationQuery.load(member.club_id, "member@example.com")

    MembershipProjection
    |> where([membership], membership.membership_id == ^member.membership_id)
    |> Repo.update_all(set: [active: false])

    assert {:error, :forbidden} =
             MemberGroupCreationQuery.load(member.club_id, "member@example.com")
  end

  test "freshly rejects loss of manage-members permission" do
    member = create_authorized_member()

    assert {:ok, _context} =
             MemberGroupCreationQuery.load(member.club_id, "member@example.com")

    MemberPermission
    |> where([permission], permission.club_id == ^member.club_id)
    |> where([permission], permission.membership_id == ^member.membership_id)
    |> where([permission], permission.person_id == ^member.person_id)
    |> where(
      [permission],
      permission.permission == ^Permissions.club_manage_members()
    )
    |> Repo.delete_all()

    assert {:error, :forbidden} =
             MemberGroupCreationQuery.load(member.club_id, "member@example.com")
  end

  test "another club's manage-members permission cannot authorize the selected club" do
    member = create_authorized_member()
    other_club = insert_membership_club!(name: "Other Club")
    other_membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: other_membership_id,
      club_id: other_club.club_id,
      person_id: member.person_id,
      active: true
    })

    Repo.insert!(%MemberPermission{
      club_id: other_club.club_id,
      membership_id: other_membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })

    MemberPermission
    |> where([permission], permission.club_id == ^member.club_id)
    |> Repo.delete_all()

    assert {:error, :forbidden} =
             MemberGroupCreationQuery.load(member.club_id, "member@example.com")

    assert {:ok, context} =
             MemberGroupCreationQuery.load(other_club.club_id, "member@example.com")

    assert context.current_member.membership_id == other_membership_id
  end

  test "fails closed for missing, invalid, inactive, and foreign contexts" do
    member = create_authorized_member()

    invalid_contexts = [
      {nil, "member@example.com"},
      {"not-a-club-id", "member@example.com"},
      {Memba.ID.generate(:club), "member@example.com"},
      {member.club_id, nil},
      {member.club_id, ""},
      {member.club_id, "unknown@example.com"}
    ]

    for {club_id, authenticated_email} <- invalid_contexts do
      assert {:error, :forbidden} =
               MemberGroupCreationQuery.load(club_id, authenticated_email)
    end
  end

  defp create_authorized_member do
    club = insert_membership_club!(name: "Query Club")

    person =
      insert_membership_person!(
        name: "Member Example",
        email: "member@example.com"
      )

    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: membership_id,
      club_id: club.club_id,
      person_id: person.person_id,
      active: true
    })

    Repo.insert!(%MemberPermission{
      club_id: club.club_id,
      membership_id: membership_id,
      person_id: person.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })

    %{
      club_id: club.club_id,
      membership_id: membership_id,
      person_id: person.person_id
    }
  end
end
