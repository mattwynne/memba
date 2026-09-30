defmodule MembaWeb.MemberDashboardQueryTest do
  use Memba.DataCase, async: false

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias MembaWeb.MemberDashboardQuery

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
