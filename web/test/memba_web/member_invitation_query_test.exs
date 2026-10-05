defmodule MembaWeb.MemberInvitationQueryTest do
  use Memba.DataCase, async: false

  alias LiveQuery.Query
  alias LiveQuery.Source

  alias Memba.Membership.Events.{
    ClubMemberAdded,
    ClubMemberRemoved,
    ClubRoleAssignedToMember,
    ClubRoleDefined,
    ClubRolePermissionGranted,
    ClubUpdated,
    PersonCreated
  }

  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.MemberInvitationQuery

  test "describes and loads one coherent invitation context with exact interests" do
    member = create_authorized_member()
    query = MemberInvitationQuery.query()

    assert query.id == :member_invitation
    assert query.assign == :invitation_context

    assert {:ok, context, interests} =
             Query.load(query, %{
               club_id: member.club_id,
               authenticated_email: "  MEMBER@EXAMPLE.COM "
             })

    assert Map.keys(context) |> Enum.sort() == [
             :active_member_count,
             :current_member,
             :selected_club
           ]

    assert context.selected_club.club_id == member.club_id
    assert context.current_member.id == member.person_id
    assert context.current_member.membership_id == member.membership_id
    assert context.active_member_count == 1

    expected_interests = [
      {:club, member.club_id},
      {:club_members, member.club_id},
      {:membership, member.membership_id},
      {:person, member.person_id},
      {:person_club, member.club_id, member.person_id},
      {:member_roles, member.club_id, member.membership_id, member.person_id},
      {:member_permissions, member.club_id, member.membership_id, member.person_id},
      {:club_roles, member.club_id},
      {:club_permissions, member.club_id}
    ]

    assert MapSet.new(interests) == MapSet.new(expected_interests)
    assert length(interests) == length(expected_interests)
    refute {:person_clubs, member.person_id} in interests

    excluded_result_keys = [
      :invitation,
      :email,
      :form,
      :errors,
      :validation,
      :pending,
      :resend,
      :delivery_feedback,
      :command_result,
      :route_params,
      :flash,
      :navigation
    ]

    refute Enum.any?(excluded_result_keys, &Map.has_key?(context, &1))
  end

  test "resolves attached-email authentication to the selected-club member by Person ID" do
    member = create_authorized_member()

    insert_membership_person_email_address!(
      person_id: member.person_id,
      email: "member.attached@example.com",
      is_primary: false
    )

    assert {:ok, context} =
             MemberInvitationQuery.load(
               member.club_id,
               " MEMBER.ATTACHED@EXAMPLE.COM "
             )

    assert context.current_member.id == member.person_id
    assert context.current_member.email == "member@example.com"
  end

  test "fresh reads update the active-member count when another selected-club member enters and leaves" do
    member = create_authorized_member()

    assert {:ok, initial_context} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    assert initial_context.active_member_count == 1

    entrant = create_member(member.club_id, "Entrant Example", "entrant@example.com")

    assert {:ok, after_entry} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    assert after_entry.active_member_count == 2

    deactivate_membership(entrant.membership_id)

    assert {:ok, after_exit} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    assert after_exit.active_member_count == 1
  end

  test "freshly rejects selected-club membership and manage-members permission loss" do
    member = create_authorized_member()

    assert {:ok, _context} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    delete_manage_members_permission(member)

    assert {:error, :forbidden} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    grant_manage_members_permission(member)
    deactivate_membership(member.membership_id)

    assert {:error, :forbidden} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")
  end

  test "fails closed for missing, invalid, inactive, foreign, and unresolved contexts" do
    member = create_authorized_member()
    inactive_club = insert_membership_club!(name: "Inactive Club")
    inactive_member = create_member(inactive_club.club_id, "Inactive", "inactive@example.com")
    deactivate_membership(inactive_member.membership_id)
    foreign_club = insert_membership_club!(name: "Foreign Club")

    invalid_contexts = [
      {nil, "member@example.com"},
      {"not-a-club-id", "member@example.com"},
      {Memba.ID.generate(:club), "member@example.com"},
      {inactive_club.club_id, "inactive@example.com"},
      {foreign_club.club_id, "member@example.com"},
      {member.club_id, nil},
      {member.club_id, ""},
      {member.club_id, "unknown@example.com"}
    ]

    for {club_id, authenticated_email} <- invalid_contexts do
      assert {:error, :forbidden} =
               MemberInvitationQuery.load(club_id, authenticated_email)
    end
  end

  test "accepted source notifications intersect every invitation interest family" do
    member = create_authorized_member()

    assert {:ok, context} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    interests = MemberInvitationQuery.interests(context)
    source = MembaReadModelSource.new()
    role_id = Memba.ID.generate(:role)

    matching_notifications = [
      notification(
        Memba.Membership.Projectors.Club,
        %ClubUpdated{club_id: member.club_id, name: "Updated Club", slug: "updated-club"}
      ),
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberAdded{
          club_id: member.club_id,
          membership_id: member.membership_id,
          person_id: member.person_id
        }
      ),
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberAdded{
          club_id: member.club_id,
          membership_id: Memba.ID.generate(:membership),
          person_id: Memba.ID.generate(:person)
        }
      ),
      notification(
        Memba.Membership.Projectors.Person,
        %PersonCreated{
          person_id: member.person_id,
          name: "Member Example",
          email: "member@example.com"
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRoleAssignedToMember{
          club_id: member.club_id,
          membership_id: member.membership_id,
          person_id: member.person_id,
          role_id: role_id
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRoleDefined{
          club_id: member.club_id,
          role_id: role_id,
          role_key: "organizer",
          name: "Organizer"
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRolePermissionGranted{
          club_id: member.club_id,
          role_id: role_id,
          permission: Permissions.club_manage_members()
        }
      )
    ]

    for matching_notification <- matching_notifications do
      assert notification_matches?(source, interests, matching_notification)
    end
  end

  test "unrelated source notifications stay isolated, including the same Person in another club" do
    member = create_authorized_member()

    assert {:ok, context} =
             MemberInvitationQuery.load(member.club_id, "member@example.com")

    interests = MemberInvitationQuery.interests(context)
    source = MembaReadModelSource.new()
    foreign_club_id = Memba.ID.generate(:club)

    unrelated_notifications = [
      notification(
        Memba.Membership.Projectors.Club,
        %ClubUpdated{club_id: foreign_club_id, name: "Foreign", slug: "foreign"}
      ),
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberAdded{
          club_id: foreign_club_id,
          membership_id: Memba.ID.generate(:membership),
          person_id: member.person_id
        }
      ),
      notification(
        Memba.Membership.Projectors.Person,
        %PersonCreated{
          person_id: Memba.ID.generate(:person),
          name: "Another Person",
          email: "another@example.com"
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRoleAssignedToMember{
          club_id: member.club_id,
          membership_id: Memba.ID.generate(:membership),
          person_id: Memba.ID.generate(:person),
          role_id: Memba.ID.generate(:role)
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRoleDefined{
          club_id: foreign_club_id,
          role_id: Memba.ID.generate(:role),
          role_key: "organizer",
          name: "Organizer"
        }
      ),
      notification(
        Memba.Membership.Projectors.Role,
        %ClubRolePermissionGranted{
          club_id: foreign_club_id,
          role_id: Memba.ID.generate(:role),
          permission: Permissions.club_manage_members()
        }
      )
    ]

    for unrelated_notification <- unrelated_notifications do
      refute notification_matches?(source, interests, unrelated_notification)
    end

    selected_club_exit =
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberRemoved{
          club_id: member.club_id,
          membership_id: Memba.ID.generate(:membership),
          person_id: Memba.ID.generate(:person)
        }
      )

    assert notification_matches?(source, interests, selected_club_exit)
    refute {:person_clubs, member.person_id} in interests
  end

  defp create_authorized_member do
    club = insert_membership_club!(name: "Query Club")
    member = create_member(club.club_id, "Member Example", "member@example.com")
    grant_manage_members_permission(member)
    member
  end

  defp create_member(club_id, name, email) do
    person = insert_membership_person!(name: name, email: email)

    membership =
      Repo.insert!(%MembershipProjection{
        membership_id: Memba.ID.generate(:membership),
        club_id: club_id,
        person_id: person.person_id,
        active: true
      })

    %{
      club_id: club_id,
      membership_id: membership.membership_id,
      person_id: person.person_id
    }
  end

  defp grant_manage_members_permission(member) do
    Repo.insert!(%MemberPermission{
      club_id: member.club_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      permission: Permissions.club_manage_members(),
      grant_count: 1
    })
  end

  defp delete_manage_members_permission(member) do
    MemberPermission
    |> where([permission], permission.club_id == ^member.club_id)
    |> where([permission], permission.membership_id == ^member.membership_id)
    |> where([permission], permission.person_id == ^member.person_id)
    |> where(
      [permission],
      permission.permission == ^Permissions.club_manage_members()
    )
    |> Repo.delete_all()
  end

  defp deactivate_membership(membership_id) do
    MembershipProjection
    |> where([membership], membership.membership_id == ^membership_id)
    |> Repo.update_all(set: [active: false])
  end

  defp notification(projector, event) do
    {:read_model_changed,
     %{projector: projector, source_event: event, metadata: %{}, changes: %{}}}
  end

  defp notification_matches?(source, interests, notification) do
    assert {:ok, invalidations} = Source.classify(source, notification)

    Enum.any?(interests, fn interest ->
      Enum.any?(invalidations, &Source.matches?(source, interest, &1))
    end)
  end
end
