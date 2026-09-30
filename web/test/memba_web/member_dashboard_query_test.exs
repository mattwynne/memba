defmodule MembaWeb.MemberDashboardQueryTest do
  use Memba.DataCase, async: false

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias MembaWeb.MemberDashboardQuery
  alias MembaWeb.LiveQuery.Query

  test "reloads active-club authority from the normalized authenticated email on every call" do
    alice = create_active_member(email: "Alice@Example.com", club_name: "Alpine Club")

    stale_active_clubs = Accounts.list_active_clubs_for_email("alice@example.com")

    assert {:ok, dashboard} =
             MemberDashboardQuery.load(
               alice.club_id,
               " ALICE@EXAMPLE.COM ",
               nil
             )

    assert dashboard.selected_club.club_id == alice.club_id
    assert dashboard.current_member.id == alice.person_id

    assert {:ok, bound_dashboard, interests} =
             Query.load(MemberDashboardQuery.query(), %{
               club_id: alice.club_id,
               authenticated_email: " ALICE@EXAMPLE.COM ",
               selected_group_id: nil
             })

    assert bound_dashboard.selected_club.club_id == alice.club_id
    assert {:club_members, alice.club_id} in interests
    assert {:person, alice.person_id} in interests

    MembershipProjection
    |> where([membership], membership.membership_id == ^alice.membership_id)
    |> Repo.update_all(set: [active: false])

    assert Enum.any?(stale_active_clubs, &(&1.club_id == alice.club_id))

    assert {:error, :forbidden} =
             MemberDashboardQuery.load(
               alice.club_id,
               " ALICE@EXAMPLE.COM ",
               nil
             )
  end

  test "preserves the presentation boundary's selected-group not-found semantics" do
    alice = create_active_member(email: "alice@example.com", club_name: "Alpine Club")

    assert {:error, :not_found} =
             MemberDashboardQuery.load(
               alice.club_id,
               "alice@example.com",
               Memba.ID.generate(:group)
             )
  end

  test "the provisional descriptor returns one dashboard and replacement interests" do
    query = MemberDashboardQuery.query()

    assert query.id == :member_dashboard
    assert query.assign == :dashboard

    dashboard = %{
      selected_club: %{club_id: "club-1"},
      selected_group: %{group_id: "group-1"},
      current_member: %{
        id: "person-1",
        membership_id: "membership-1",
        roles: ["Membership Admin"]
      },
      groups: [
        %{club_id: "club-1", group_id: "group-1"},
        %{club_id: "club-1", group_id: "group-2"}
      ],
      members: [
        %{id: "person-1", membership_id: "membership-1", roles: ["Membership Admin"]},
        %{id: "person-2", membership_id: "membership-2", roles: ["Trip Lead"]}
      ],
      custom_group_member_candidates: [
        %{id: "person-3", membership_id: "membership-3", roles: []}
      ],
      message_rows: [
        %{
          message_id: "message-1",
          conversation_id: "conversation-1",
          sender_id: "person-4",
          originator_id: "person-5",
          latest_replier_id: "person-6",
          participants: [%{id: "person-7"}, %{id: "person-4"}]
        }
      ]
    }

    interests = MemberDashboardQuery.interests(dashboard)

    for collection_interest <- [
          {:club_members, "club-1"},
          {:club_groups, "club-1"},
          {:person_groups, "club-1", "person-1"},
          {:group_members, "group-1"},
          {:group_conversations, "group-1"},
          {:club_conversations, "club-1"}
        ] do
      assert collection_interest in interests
    end

    for identity_interest <- [
          {:club, "club-1"},
          {:group, "group-1"},
          {:group, "group-2"},
          {:membership, "membership-1"},
          {:person, "person-1"},
          {:person, "person-2"},
          {:person, "person-3"},
          {:person, "person-4"},
          {:person, "person-5"},
          {:person, "person-6"},
          {:person, "person-7"},
          {:conversation, "conversation-1"},
          {:conversation_messages, "conversation-1"},
          {:message, "message-1"}
        ] do
      assert identity_interest in interests
    end

    for role_interest <- [
          {:member_roles, "club-1", "membership-1", "person-1"},
          {:member_roles, "club-1", "membership-2", "person-2"},
          {:member_roles, "club-1", "membership-3", "person-3"},
          {:member_permissions, "club-1", "membership-1", "person-1"},
          {:club_roles, "club-1"},
          {:club_permissions, "club-1"}
        ] do
      assert role_interest in interests
    end

    assert {:conversation_access, "group-1", "conversation-1"} in interests
    assert {:group_participation, "club-1", "group-1", "person-1"} in interests
    refute {:member_permissions, "club-1", "membership-2", "person-2"} in interests
  end

  defp create_active_member(attrs) do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.create_club(
               membership_club_attrs(
                 club_id: club_id,
                 name: Keyword.fetch!(attrs, :club_name)
               ),
               consistency: :strong
             )

    person =
      insert_membership_person!(
        person_id: person_id,
        name: "Alice Adams",
        email: Keyword.fetch!(attrs, :email)
      )

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person.person_id
               },
               consistency: :strong
             )

    %{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person.person_id
    }
  end
end
