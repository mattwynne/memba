defmodule MembaWeb.MemberSettingsQueryTest do
  use Memba.DataCase, async: false

  alias LiveQuery.Query
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias MembaWeb.MemberSettingsQuery

  test "describes and loads one coherent settings result with exact interests" do
    settings = create_settings_context()
    query = MemberSettingsQuery.query()

    assert query.id == :member_settings
    assert query.assign == :settings

    assert {:ok, result, interests} =
             Query.load(query, %{
               club_id: settings.selected_club_id,
               authenticated_email: "  MEMBER@EXAMPLE.COM "
             })

    assert Map.keys(result) |> Enum.sort() == [
             :current_person,
             :current_person_clubs,
             :current_person_email_addresses,
             :selected_club
           ]

    assert result.selected_club.club_id == settings.selected_club_id
    assert result.current_person.person_id == settings.person_id

    assert Enum.map(result.current_person_clubs, & &1.club_id) == [
             settings.selected_club_id,
             settings.other_club_id
           ]

    assert Enum.map(result.current_person_email_addresses, & &1.email) == [
             "member@example.com",
             "member.alternate@example.com"
           ]

    expected_interests = [
      {:person, settings.person_id},
      {:person_emails, settings.person_id},
      {:person_clubs, settings.person_id},
      {:person_club, settings.selected_club_id, settings.person_id},
      {:club, settings.selected_club_id},
      {:club, settings.other_club_id}
    ]

    assert MapSet.new(interests) == MapSet.new(expected_interests)
    assert length(interests) == 6

    excluded_result_keys = [
      :active_tab,
      :add_email_form,
      :add_email_error,
      :command,
      :flash,
      :navigation,
      :group,
      :role,
      :permission,
      :message,
      :delivery
    ]

    refute Enum.any?(excluded_result_keys, &Map.has_key?(result, &1))

    excluded_interest_names = [
      :club_members,
      :membership,
      :group,
      :group_members,
      :group_participation,
      :member_roles,
      :member_permissions,
      :club_roles,
      :club_permissions,
      :message,
      :conversation,
      :delivery,
      :message_deliveries
    ]

    refute Enum.any?(interests, fn interest ->
             elem(interest, 0) in excluded_interest_names
           end)
  end

  test "normalizes an attached authenticated email and resolves the same Person settings" do
    settings = create_settings_context()

    assert {:ok, result} =
             MemberSettingsQuery.load(
               settings.selected_club_id,
               "  MEMBER.ALTERNATE@EXAMPLE.COM "
             )

    assert result.current_person.person_id == settings.person_id
    assert result.current_person.email == "member@example.com"
    assert result.selected_club.club_id == settings.selected_club_id

    assert Enum.map(result.current_person_clubs, & &1.club_id) == [
             settings.selected_club_id,
             settings.other_club_id
           ]

    assert Enum.map(result.current_person_email_addresses, & &1.email) == [
             "member@example.com",
             "member.alternate@example.com"
           ]
  end

  test "freshly replaces active memberships and represented Club interests" do
    settings = create_settings_context()
    query = MemberSettingsQuery.query()

    inputs = %{
      club_id: settings.selected_club_id,
      authenticated_email: "member@example.com"
    }

    assert {:ok, initial_result, initial_interests} = Query.load(query, inputs)

    assert Enum.map(initial_result.current_person_clubs, & &1.club_id) == [
             settings.selected_club_id,
             settings.other_club_id
           ]

    assert {:club, settings.other_club_id} in initial_interests

    MembershipProjection
    |> where(
      [membership],
      membership.membership_id == ^settings.other_membership_id
    )
    |> Repo.update_all(set: [active: false])

    assert {:ok, result_after_departure, interests_after_departure} =
             Query.load(query, inputs)

    assert Enum.map(result_after_departure.current_person_clubs, & &1.club_id) == [
             settings.selected_club_id
           ]

    refute {:club, settings.other_club_id} in interests_after_departure
    assert length(interests_after_departure) == 5

    entered_club = insert_membership_club!(name: "Third Club")
    entered_membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: entered_membership_id,
      club_id: entered_club.club_id,
      person_id: settings.person_id,
      active: true
    })

    assert {:ok, result_after_entry, interests_after_entry} = Query.load(query, inputs)

    assert Enum.map(result_after_entry.current_person_clubs, & &1.club_id) == [
             settings.selected_club_id,
             entered_club.club_id
           ]

    assert {:club, entered_club.club_id} in interests_after_entry
    refute {:club, settings.other_club_id} in interests_after_entry
    assert length(interests_after_entry) == 6
  end

  test "freshly rejects selected-club membership loss" do
    settings = create_settings_context()

    assert {:ok, _result} =
             MemberSettingsQuery.load(
               settings.selected_club_id,
               "member@example.com"
             )

    MembershipProjection
    |> where(
      [membership],
      membership.membership_id == ^settings.selected_membership_id
    )
    |> Repo.update_all(set: [active: false])

    assert {:error, :forbidden} =
             MemberSettingsQuery.load(
               settings.selected_club_id,
               "member@example.com"
             )
  end

  test "fails closed for missing, invalid, inactive, foreign, and unresolved contexts" do
    settings = create_settings_context()

    inactive_club = insert_membership_club!(name: "Inactive Club")

    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: inactive_club.club_id,
      person_id: settings.person_id,
      active: false
    })

    foreign_club = insert_membership_club!(name: "Foreign Club")

    invalid_contexts = [
      {nil, "member@example.com"},
      {"not-a-club-id", "member@example.com"},
      {inactive_club.club_id, "member@example.com"},
      {foreign_club.club_id, "member@example.com"},
      {settings.selected_club_id, nil},
      {settings.selected_club_id, ""},
      {settings.selected_club_id, "unknown@example.com"}
    ]

    for {club_id, authenticated_email} <- invalid_contexts do
      assert {:error, :forbidden} =
               MemberSettingsQuery.load(club_id, authenticated_email)
    end
  end

  defp create_settings_context do
    selected_club = insert_membership_club!(name: "Alpha Club")
    other_club = insert_membership_club!(name: "Beta Club")

    person =
      insert_membership_person!(
        name: "Member Example",
        email: "member@example.com"
      )

    insert_membership_person_email_address!(
      person_id: person.person_id,
      email: "member.alternate@example.com",
      is_primary: false
    )

    selected_membership_id = Memba.ID.generate(:membership)
    other_membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: selected_membership_id,
      club_id: selected_club.club_id,
      person_id: person.person_id,
      active: true
    })

    Repo.insert!(%MembershipProjection{
      membership_id: other_membership_id,
      club_id: other_club.club_id,
      person_id: person.person_id,
      active: true
    })

    %{
      selected_club_id: selected_club.club_id,
      selected_membership_id: selected_membership_id,
      other_club_id: other_club.club_id,
      other_membership_id: other_membership_id,
      person_id: person.person_id
    }
  end
end
