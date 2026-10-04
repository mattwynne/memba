defmodule MembaWeb.MemberMessageComposeQueryTest do
  use Memba.DataCase, async: false

  alias LiveQuery.Query
  alias Memba.Membership.Projections.Group, as: GroupProjection
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.SystemGroups
  alias MembaWeb.MemberMessageComposeQuery

  test "describes and loads the default Everyone compose context with complete interests" do
    context = create_compose_context()
    query = MemberMessageComposeQuery.query()

    assert query.id == :member_message_compose
    assert query.assign == :compose_context

    assert {:ok, result, interests} =
             Query.load(query, %{
               club_id: context.club_id,
               authenticated_email: "  MEMBER@EXAMPLE.COM "
             })

    assert Map.keys(result) |> Enum.sort() == [
             :active_member_count,
             :audience_group,
             :current_member,
             :message_audience,
             :selected_club
           ]

    assert result.selected_club.club_id == context.club_id
    assert result.current_member.id == context.current.person_id
    assert result.current_member.membership_id == context.current.membership_id
    assert result.audience_group.group_id == context.everyone_group.group_id
    assert result.active_member_count == 2

    assert result.message_audience == %{
             club_name: "Query Club",
             group_id: context.everyone_group.group_id,
             group_name: SystemGroups.everyone_name(),
             active_member_count: 2,
             recipient_count_summary: "2 members",
             inbound_email_address: result.audience_group.email_address
           }

    expected_interests = [
      {:club, context.club_id},
      {:club_members, context.club_id},
      {:membership, context.current.membership_id},
      {:person, context.current.person_id},
      {:person_club, context.club_id, context.current.person_id},
      {:person_groups, context.club_id, context.current.person_id},
      {:group, context.everyone_group.group_id},
      {:group_members, context.everyone_group.group_id},
      {:group_participation, context.club_id, context.everyone_group.group_id,
       context.current.person_id},
      {:person_emails, context.current.person_id},
      {:person, context.eligible.person_id},
      {:person_emails, context.eligible.person_id},
      {:person, context.ineligible.person_id},
      {:person_emails, context.ineligible.person_id}
    ]

    assert MapSet.new(interests) == MapSet.new(expected_interests)
    assert length(interests) == length(expected_interests)

    excluded_result_keys = [
      :subject,
      :body,
      :form,
      :message_form,
      :validation,
      :errors,
      :compose_state,
      :send_error,
      :retry,
      :flash,
      :route_params,
      :navigation,
      :participants,
      :members
    ]

    refute Enum.any?(excluded_result_keys, &Map.has_key?(result, &1))
  end

  test "normalizes attached-email identity and selects an explicit participating group" do
    context = create_compose_context()

    insert_membership_person_email_address!(
      person_id: context.current.person_id,
      email: "member.attached@example.com",
      is_primary: false
    )

    group = create_group(context.club_id, "Trip Leaders", "trip-leaders")
    add_group_participant(group, context.current)
    add_group_participant(group, context.eligible)

    assert {:ok, result} =
             MemberMessageComposeQuery.load(
               context.club_id,
               group.group_id,
               "  MEMBER.ATTACHED@EXAMPLE.COM "
             )

    assert result.current_member.id == context.current.person_id
    assert result.current_member.email == "member@example.com"
    assert result.audience_group.group_id == group.group_id
    assert result.active_member_count == 2
    assert result.message_audience.group_name == "Trip Leaders"
    assert result.message_audience.recipient_count_summary == "2 members"
  end

  test "preserves forbidden defaults and not-found explicit audience behavior" do
    context = create_compose_context()
    unknown_group_id = Memba.ID.generate(:group)
    unavailable_group = create_group(context.club_id, "Unavailable", "unavailable")

    foreign_club = insert_membership_club!(name: "Foreign Club")
    foreign_group = create_group(foreign_club.club_id, "Foreign", "foreign")

    assert {:error, :not_found} =
             MemberMessageComposeQuery.load(
               context.club_id,
               unknown_group_id,
               "member@example.com"
             )

    assert {:error, :not_found} =
             MemberMessageComposeQuery.load(
               context.club_id,
               unavailable_group.group_id,
               "member@example.com"
             )

    assert {:error, :not_found} =
             MemberMessageComposeQuery.load(
               context.club_id,
               foreign_group.group_id,
               "member@example.com"
             )

    deactivate_group_participant(context.everyone_group, context.current)

    assert {:error, :forbidden} =
             MemberMessageComposeQuery.load(
               context.club_id,
               nil,
               "member@example.com"
             )
  end

  test "freshly rejects club-membership and explicit group-participation loss" do
    context = create_compose_context()
    group = create_group(context.club_id, "Trip Leaders", "trip-leaders")
    add_group_participant(group, context.current)

    assert {:ok, _result} =
             MemberMessageComposeQuery.load(
               context.club_id,
               group.group_id,
               "member@example.com"
             )

    deactivate_group_participant(group, context.current)

    assert {:error, :not_found} =
             MemberMessageComposeQuery.load(
               context.club_id,
               group.group_id,
               "member@example.com"
             )

    MembershipProjection
    |> where([membership], membership.membership_id == ^context.current.membership_id)
    |> Repo.update_all(set: [active: false])

    assert {:error, :forbidden} =
             MemberMessageComposeQuery.load(
               context.club_id,
               nil,
               "member@example.com"
             )
  end

  test "primary-email loss and gain update count without losing represented interests" do
    context = create_compose_context()
    query = MemberMessageComposeQuery.query()

    inputs = %{
      club_id: context.club_id,
      group_id: nil,
      authenticated_email: "member@example.com"
    }

    assert {:ok, initial_result, initial_interests} = Query.load(query, inputs)
    assert initial_result.active_member_count == 2
    assert {:person, context.ineligible.person_id} in initial_interests
    assert {:person_emails, context.ineligible.person_id} in initial_interests

    PersonEmailAddress
    |> where(
      [email_address],
      email_address.person_id == ^context.eligible.person_id and
        email_address.is_primary == true
    )
    |> Repo.delete_all()

    assert {:ok, after_loss, interests_after_loss} = Query.load(query, inputs)
    assert after_loss.active_member_count == 1
    assert {:person, context.eligible.person_id} in interests_after_loss
    assert {:person_emails, context.eligible.person_id} in interests_after_loss

    insert_membership_person_email_address!(
      person_id: context.ineligible.person_id,
      email: "ineligible@example.com",
      is_primary: true
    )

    assert {:ok, after_gain, interests_after_gain} = Query.load(query, inputs)
    assert after_gain.active_member_count == 2
    assert {:person, context.ineligible.person_id} in interests_after_gain
    assert {:person_emails, context.ineligible.person_id} in interests_after_gain
  end

  test "selected-group entry and exit replace represented interests and ignore unrelated people" do
    context = create_compose_context()
    query = MemberMessageComposeQuery.query()

    selected_group = create_group(context.club_id, "Trip Leaders", "trip-leaders")
    add_group_participant(selected_group, context.current)

    other_group = create_group(context.club_id, "Other Group", "other")
    other_group_member = create_member(context.club_id, "Other", "other@example.com")
    add_group_participant(other_group, other_group_member)

    foreign_club = insert_membership_club!(name: "Foreign Club")
    foreign_member = create_member(foreign_club.club_id, "Foreign", "foreign@example.com")
    foreign_group = create_group(foreign_club.club_id, "Foreign Group", "foreign-group")
    add_group_participant(foreign_group, foreign_member)

    entrant = create_member(context.club_id, "Entrant", "entrant@example.com")

    inputs = %{
      club_id: context.club_id,
      group_id: selected_group.group_id,
      authenticated_email: "member@example.com"
    }

    assert {:ok, initial_result, initial_interests} = Query.load(query, inputs)
    assert initial_result.active_member_count == 1
    assert initial_result.message_audience.recipient_count_summary == "1 member"
    refute {:person, entrant.person_id} in initial_interests
    refute {:person, other_group_member.person_id} in initial_interests
    refute {:person, foreign_member.person_id} in initial_interests
    refute {:group, other_group.group_id} in initial_interests
    refute {:club, foreign_club.club_id} in initial_interests

    add_group_participant(selected_group, entrant)

    assert {:ok, after_entry, interests_after_entry} = Query.load(query, inputs)
    assert after_entry.active_member_count == 2
    assert {:person, entrant.person_id} in interests_after_entry
    assert {:person_emails, entrant.person_id} in interests_after_entry

    deactivate_group_participant(selected_group, entrant)

    assert {:ok, after_exit, interests_after_exit} = Query.load(query, inputs)
    assert after_exit.active_member_count == 1
    refute {:person, entrant.person_id} in interests_after_exit
    refute {:person_emails, entrant.person_id} in interests_after_exit
  end

  test "fails closed for missing, invalid, inactive, foreign, and unresolved club contexts" do
    context = create_compose_context()
    inactive_club = insert_membership_club!(name: "Inactive Club")

    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: inactive_club.club_id,
      person_id: context.current.person_id,
      active: false
    })

    foreign_club = insert_membership_club!(name: "Foreign Club")

    invalid_contexts = [
      {nil, "member@example.com"},
      {"not-a-club-id", "member@example.com"},
      {inactive_club.club_id, "member@example.com"},
      {foreign_club.club_id, "member@example.com"},
      {context.club_id, nil},
      {context.club_id, ""},
      {context.club_id, "unknown@example.com"}
    ]

    for {club_id, authenticated_email} <- invalid_contexts do
      assert {:error, :forbidden} =
               MemberMessageComposeQuery.load(club_id, nil, authenticated_email)
    end
  end

  defp create_compose_context do
    club = insert_membership_club!(name: "Query Club")
    current = create_member(club.club_id, "Member Example", "member@example.com")
    eligible = create_member(club.club_id, "Eligible Example", "eligible@example.com")
    ineligible = create_member_without_primary_email(club.club_id, "Ineligible Example")
    everyone_group = create_everyone_group(club.club_id)

    add_group_participant(everyone_group, current)
    add_group_participant(everyone_group, eligible)
    add_group_participant(everyone_group, ineligible)

    %{
      club_id: club.club_id,
      current: current,
      eligible: eligible,
      ineligible: ineligible,
      everyone_group: everyone_group
    }
  end

  defp create_member(club_id, name, email) do
    person = insert_membership_person!(name: name, email: email)
    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    %{membership_id: membership_id, person_id: person.person_id}
  end

  defp create_member_without_primary_email(club_id, name) do
    person =
      Repo.insert!(%Person{
        person_id: Memba.ID.generate(:person),
        name: name,
        email: String.downcase(String.replace(name, " ", ".")) <> "@example.com"
      })

    membership_id = Memba.ID.generate(:membership)

    Repo.insert!(%MembershipProjection{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person.person_id,
      active: true
    })

    %{membership_id: membership_id, person_id: person.person_id}
  end

  defp create_everyone_group(club_id) do
    Repo.insert!(%GroupProjection{
      club_id: club_id,
      group_id: SystemGroups.everyone_group_id(club_id),
      email_slug: SystemGroups.everyone_email_slug(),
      group_key: SystemGroups.everyone_key(),
      name: SystemGroups.everyone_name(),
      name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key(SystemGroups.everyone_name())
    })
  end

  defp create_group(club_id, name, email_slug) do
    Repo.insert!(%GroupProjection{
      club_id: club_id,
      group_id: Memba.ID.generate(:group),
      email_slug: email_slug,
      group_key: "custom:#{email_slug}",
      name: name,
      name_uniqueness_key: Memba.Membership.GroupName.uniqueness_key(name)
    })
  end

  defp add_group_participant(group, member) do
    Repo.insert!(%GroupMembershipProjection{
      club_id: group.club_id,
      group_id: group.group_id,
      membership_id: member.membership_id,
      person_id: member.person_id,
      active: true
    })
  end

  defp deactivate_group_participant(group, member) do
    GroupMembershipProjection
    |> where(
      [group_membership],
      group_membership.group_id == ^group.group_id and
        group_membership.membership_id == ^member.membership_id
    )
    |> Repo.update_all(set: [active: false])
  end
end
