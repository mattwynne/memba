defmodule Memba.Cucumber.ClubMemberInvitationSteps do
  use Cucumber.StepDefinition

  import Ecto.Query
  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles
  alias Memba.Membership.Slug
  alias Memba.Repo

  step "{word} is signed in as Memba staff", %{args: [person_name]} = context do
    context
    |> ensure_person(person_name, staff_email_for(person_name))
    |> sign_in_as(person_name)
  end

  step "{word} {word} {word} exists as a club",
       %{args: [word_1, word_2, word_3]} = context do
    ensure_club(context, club_name(word_1, word_2, word_3))
  end

  step "{word} is a person in Memba", %{args: [person_name]} = context do
    ensure_person(context, person_name)
  end

  step "{word} is not a member of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)

    context =
      context
      |> ensure_club(club_name)
      |> ensure_person(person_name)

    club_id = fetch_club_id!(context, club_name)
    email = email_for_person(context, person_name)

    assert active_membership_count_by_email(club_id, email) == 0
    context
  end

  step "{word} is a Membership Admin of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    ensure_membership_administrator(context, person_name, club_name(word_1, word_2, word_3))
  end

  step "{word} is an active member of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    context
    |> ensure_club(club_name(word_1, word_2, word_3))
    |> ensure_active_member(person_name, club_name(word_1, word_2, word_3))
  end

  step "{word} has invited {string} to join {word} {word} {word}",
       %{args: [actor_name, email, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)

    context
    |> ensure_staff_sign_in_if_staff_actor(actor_name)
    |> invite_email(actor_name, email, club_name)
    |> assert_invitation_received(email, club_name)
  end

  step "{word} has accepted an invitation to join {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)
    email = "#{String.downcase(person_name)}@example.com"

    context
    |> ensure_signed_in_staff("Pat")
    |> invite_email("Pat", email, club_name)
    |> assert_invitation_received(email, club_name)
    |> follow_invitation_link(person_name, club_name)
    |> enter_name(person_name, "#{person_name} Example")
    |> assert_active_member(person_name, club_name)
  end

  step "{word} invites {string} to join {word} {word} {word}",
       %{args: [actor_name, email, word_1, word_2, word_3]} = context do
    invite_email(context, actor_name, email, club_name(word_1, word_2, word_3))
  end

  step ~r/^(\w+) invites (\w+) to join (\w+) (\w+) (\w+)$/,
       %{args: [actor_name, person_name, word_1, word_2, word_3]} = context do
    context = ensure_person(context, person_name)

    invite_email(
      context,
      actor_name,
      email_for_person(context, person_name),
      club_name(word_1, word_2, word_3)
    )
  end

  step "{word} invites {string} to join {word} {word} {word} again",
       %{args: [actor_name, email, word_1, word_2, word_3]} = context do
    invite_email(context, actor_name, email, club_name(word_1, word_2, word_3))
  end

  step "{word} tries to invite {string} to join {word} {word} {word}",
       %{args: [actor_name, email, word_1, word_2, word_3]} = context do
    try_invite_email(context, actor_name, email, club_name(word_1, word_2, word_3))
  end

  step ~r/^(\w+) tries to invite (\w+) to join (\w+) (\w+) (\w+)$/,
       %{args: [actor_name, person_name, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)
    context = ensure_person(context, person_name)

    try_invite_email(context, actor_name, email_for_person(context, person_name), club_name, %{
      person_name: person_name
    })
  end

  step "{word} follows the invitation link", %{args: [person_name]} = context do
    follow_invitation_link(context, person_name, inferred_club_name(context))
  end

  step "{word} follows the same invitation link again", %{args: [person_name]} = context do
    follow_invitation_link(context, person_name, inferred_club_name(context))
  end

  step "{word} enters {string} as their name", %{args: [person_name, name]} = context do
    enter_name(context, person_name, name)
  end

  step "{word} leaves without entering their name", context do
    Map.put(context, :current_page, :away_from_profile_completion)
  end

  step "{word} wants to add a new member to {word} {word} {word}",
       %{args: [_actor_name, word_1, word_2, word_3]} = context do
    context
    |> ensure_club(club_name(word_1, word_2, word_3))
    |> Map.put(:current_page, :club_member_invitation_form)
  end

  step "{string} should receive an invitation to join {word} {word} {word}",
       %{args: [email, word_1, word_2, word_3]} = context do
    assert_invitation_received(context, email, club_name(word_1, word_2, word_3))
  end

  step "{string} should receive another invitation to join {word} {word} {word}",
       %{args: [email, word_1, word_2, word_3]} = context do
    assert_invitation_received(context, email, club_name(word_1, word_2, word_3))
  end

  step ~r/^(\w+) should receive an invitation to join (\w+) (\w+) (\w+)$/,
       %{args: [person_name, word_1, word_2, word_3]} = context do
    assert_invitation_received(
      context,
      email_for_person(context, person_name),
      club_name(word_1, word_2, word_3)
    )
  end

  step "{word} should not be an active member of {word} {word} {word} yet",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    assert_not_active_member(context, person_name, club_name(word_1, word_2, word_3))
  end

  step "{word} should still not be an active member of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    assert_not_active_member(context, person_name, club_name(word_1, word_2, word_3))
  end

  step "{word} should be asked for their name", %{args: [person_name]} = context do
    assert %{person_name: ^person_name} = Map.fetch!(context, :pending_profile_completion)
    assert Map.get(context, :current_page) == :club_member_profile_completion
    context
  end

  step "{word} should be an active member of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    assert_active_member(context, person_name, club_name(word_1, word_2, word_3))
  end

  step "{word} should be an ordinary member of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)

    context
    |> assert_active_member(person_name, club_name)
    |> refute_membership_administrator(person_name, club_name)
  end

  step "{word} should be signed in to {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)
    identity = Map.fetch!(context, :signed_in_identity)

    assert identity.email == Accounts.normalize_email(email_for_person(context, person_name))
    assert Map.get(context, :current_page) == {:club_home, club_name}
    context
  end

  step "{word} should be told they cannot invite members to {word} {word} {word}",
       %{args: [actor_name, word_1, word_2, word_3]} = context do
    expected_club_name = club_name(word_1, word_2, word_3)

    assert {:error, :unauthorized} =
             Map.fetch!(context, :last_club_member_invitation_result)

    assert %{actor_name: ^actor_name, club_name: ^expected_club_name} =
             Map.fetch!(context, :last_club_member_invitation_attempt)

    context
  end

  step "{word} should be told she cannot invite members to {word} {word} {word}",
       %{args: [actor_name, word_1, word_2, word_3]} = context do
    expected_club_name = club_name(word_1, word_2, word_3)

    assert {:error, :unauthorized} =
             Map.fetch!(context, :last_club_member_invitation_result)

    assert %{actor_name: ^actor_name, club_name: ^expected_club_name} =
             Map.fetch!(context, :last_club_member_invitation_attempt)

    context
  end

  step "{string} should not receive an invitation to join {word} {word} {word}",
       %{args: [email, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)
    normalized_email = normalize_email!(email)

    refute get_in(context, [:club_member_invitations, {club_name, normalized_email}])
    assert sent_invitation_count(context, club_name, normalized_email) == 0

    context
  end

  step "{word} should be asked for the member's email address only", context do
    assert Map.get(context, :current_page) == :club_member_invitation_form
    assert Map.get(context, :member_invitation_form_fields, [:email]) == [:email]
    context
  end

  step "{word} should not be able to create an active member directly from a name and email address",
       context do
    assert Map.get(context, :current_page) == :club_member_invitation_form
    refute Map.get(context, :member_invitation_form_fields, [:email]) == [:name, :email]
    context
  end

  step "{word} should see that {word} is already a member of {word} {word} {word}",
       %{args: [_actor_name, person_name, word_1, word_2, word_3]} = context do
    expected_club_name = club_name(word_1, word_2, word_3)

    assert {:error, :already_active_member} =
             Map.fetch!(context, :last_club_member_invitation_result)

    assert %{person_name: ^person_name, club_name: ^expected_club_name} =
             Map.fetch!(context, :last_club_member_invitation_attempt)

    context
  end

  step "there should still be only one pending invitation for {string} to join {word} {word} {word}",
       %{args: [email, word_1, word_2, word_3]} = context do
    club_name = club_name(word_1, word_2, word_3)
    club_id = fetch_club_id!(context, club_name)

    assert pending_invitation_count(club_id, email) == 1
    context
  end

  step "{word} should still have only one active membership of {word} {word} {word}",
       %{args: [person_name, word_1, word_2, word_3]} = context do
    assert_active_member(context, person_name, club_name(word_1, word_2, word_3))
  end

  defp ensure_signed_in_staff(context, person_name) do
    case Map.get(context, :signed_in_identity) do
      %{staff?: true} ->
        context

      _identity ->
        context
        |> ensure_person(person_name, staff_email_for(person_name))
        |> sign_in_as(person_name)
    end
  end

  defp ensure_staff_sign_in_if_staff_actor(context, person_name) do
    if Accounts.staff_email?(email_for_person(context, person_name)) do
      ensure_signed_in_staff(context, person_name)
    else
      context
    end
  end

  defp invite_email(context, actor_name, email, club_name) do
    normalized_email = normalize_email!(email)
    person_name = person_name_from_email(normalized_email)

    context =
      context
      |> ensure_club(club_name)
      |> put_person_email_if_missing(person_name, normalized_email)

    club_id = fetch_club_id!(context, club_name)

    :ok = authorize_invitation_actor(context, actor_name, club_id)

    assert {:ok, %{invitation_id: invitation_id, invitation_token: invitation_token}} =
             Membership.invite_club_member(%{club_id: club_id, email: normalized_email},
               consistency: :strong
             )

    context
    |> update_context_map(:club_member_invitations, {club_name, normalized_email}, %{
      actor_name: actor_name,
      club_name: club_name,
      email: normalized_email,
      invitation_id: invitation_id,
      token: invitation_token
    })
    |> update_context_map(
      :sent_club_member_invitation_counts,
      {club_name, normalized_email},
      sent_invitation_count(context, club_name, normalized_email) + 1
    )
  end

  defp try_invite_email(context, actor_name, email, club_name, attempt_attrs \\ %{}) do
    normalized_email = normalize_email!(email)

    context =
      context
      |> ensure_club(club_name)
      |> put_person_email_if_missing(person_name_from_email(normalized_email), normalized_email)

    club_id = fetch_club_id!(context, club_name)

    result =
      with :ok <- authorize_invitation_actor(context, actor_name, club_id) do
        Membership.invite_club_member(%{club_id: club_id, email: normalized_email},
          consistency: :strong
        )
      end

    context
    |> Map.put(:last_club_member_invitation_result, result)
    |> Map.put(
      :last_club_member_invitation_attempt,
      Map.merge(
        %{
          actor_name: actor_name,
          club_name: club_name,
          email: normalized_email
        },
        attempt_attrs
      )
    )
  end

  defp authorize_invitation_actor(context, actor_name, club_id) do
    if staff_actor?(context, actor_name) do
      :ok
    else
      actor = fetch_person!(context, actor_name)
      Authorization.authorize_manage_members(club_id, actor.person_id)
    end
  end

  defp assert_invitation_received(context, recipient, club_name) do
    email =
      if String.contains?(recipient, "@"),
        do: normalize_email!(recipient),
        else: email_for_person(context, recipient)

    invitation = fetch_from_context!(context, :club_member_invitations, {club_name, email})

    assert %ClubInvitation{} = Membership.get_club_member_invitation(invitation.invitation_id)
    assert is_binary(invitation.token)
    assert sent_invitation_count(context, club_name, email) >= 1

    context
  end

  defp follow_invitation_link(context, person_name, club_name) do
    email = email_for_person(context, person_name)
    %{token: token} = fetch_from_context!(context, :club_member_invitations, {club_name, email})

    case Membership.get_club_member_invitation_by_token(token) do
      %ClubInvitation{status: "pending"} = invitation ->
        case Membership.get_person_by_email(invitation.normalized_email) do
          %PersonProjection{} = person ->
            assert {:ok, _acceptance} =
                     Membership.accept_club_member_invitation_for_existing_person(
                       %{invitation_id: invitation.invitation_id, person_id: person.person_id},
                       consistency: :strong
                     )

            context
            |> remember_person(person_name, person)
            |> remember_active_membership(person_name, club_name)
            |> sign_in_email(invitation.normalized_email)
            |> Map.put(:current_page, {:club_home, club_name})

          nil ->
            context
            |> sign_in_email(invitation.normalized_email)
            |> Map.put(:current_page, :club_member_profile_completion)
            |> Map.put(:pending_profile_completion, %{
              club_name: club_name,
              email: invitation.normalized_email,
              invitation_id: invitation.invitation_id,
              person_name: person_name
            })
        end

      %ClubInvitation{status: "accepted"} = invitation ->
        context
        |> sign_in_email(invitation.normalized_email)
        |> Map.put(:current_page, {:club_home, club_name})

      nil ->
        flunk("Expected #{person_name} to have a valid invitation token for #{club_name}")
    end
  end

  defp enter_name(context, person_name, name) do
    journey = Map.fetch!(context, :pending_profile_completion)

    assert {:ok, %{person_id: person_id, membership_id: membership_id}} =
             Membership.complete_invited_club_member_profile(
               %{invitation_id: journey.invitation_id, name: name},
               consistency: :strong
             )

    person = Membership.get_person(person_id)

    context
    |> update_context_map(:people, person_name, %{
      person_id: person_id,
      name: person.name,
      email: person.email
    })
    |> update_context_map(:memberships, {journey.club_name, person_name}, membership_id)
    |> sign_in_email(journey.email)
    |> Map.delete(:pending_profile_completion)
    |> Map.put(:current_page, {:club_home, journey.club_name})
  end

  defp assert_not_active_member(context, person_name, club_name) do
    club_id = fetch_club_id!(context, club_name)
    email = email_for_person(context, person_name)

    assert active_membership_count_by_email(club_id, email) == 0
    context
  end

  defp assert_active_member(context, person_name, club_name) do
    club_id = fetch_club_id!(context, club_name)
    email = email_for_person(context, person_name)

    assert active_membership_count_by_email(club_id, email) == 1
    context
  end

  defp ensure_active_member(context, person_name, club_name) do
    context =
      context
      |> ensure_club(club_name)
      |> ensure_person(person_name)

    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)

    case active_membership_id(club_id, person.person_id) do
      nil ->
        membership_id = Memba.ID.generate(:membership)

        assert :ok =
                 Membership.add_member(
                   %{membership_id: membership_id, club_id: club_id, person_id: person.person_id},
                   consistency: :strong
                 )

        update_context_map(context, :memberships, {club_name, person_name}, membership_id)

      membership_id ->
        update_context_map(context, :memberships, {club_name, person_name}, membership_id)
    end
  end

  defp ensure_membership_administrator(context, person_name, club_name) do
    context = ensure_active_member(context, person_name, club_name)
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    membership_id = active_membership_id!(club_id, person.person_id)
    role_id = Roles.membership_administrator_role_id(club_id)

    unless active_role_assignment?(club_id, membership_id, person.person_id, role_id) do
      assert :ok =
               App.dispatch(
                 %AssignMemberRole{
                   club_id: club_id,
                   membership_id: membership_id,
                   person_id: person.person_id,
                   role_id: role_id
                 },
                 consistency: :strong
               )
    end

    assert Membership.person_has_club_permission?(
             club_id,
             person.person_id,
             Permissions.club_manage_members()
           )

    context
  end

  defp refute_membership_administrator(context, person_name, club_name) do
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    membership_id = active_membership_id!(club_id, person.person_id)
    role_id = Roles.membership_administrator_role_id(club_id)

    refute active_role_assignment?(club_id, membership_id, person.person_id, role_id)

    refute Membership.person_has_club_permission?(
             club_id,
             person.person_id,
             Permissions.club_manage_members()
           )

    context
  end

  defp ensure_club(context, club_name) do
    if get_in(context, [:clubs, club_name]) do
      context
    else
      slug = scenario_slug(context, club_name)

      club =
        case Membership.get_club_by_slug(slug) do
          %ClubProjection{} = club ->
            club

          nil ->
            club_id = Memba.ID.generate(:club)

            assert :ok =
                     Membership.create_club(
                       %{club_id: club_id, name: club_name, slug: slug},
                       consistency: :strong
                     )

            Membership.get_club(club_id)
        end

      update_context_map(context, :clubs, club_name, club.club_id)
    end
  end

  defp ensure_person(context, person_name, email \\ nil) do
    email = email || default_email_for(context, person_name)

    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        context

      _missing ->
        case Membership.get_person_by_email(email) do
          %PersonProjection{} = person ->
            remember_person(context, person_name, person)

          nil ->
            person_id = Memba.ID.generate(:person)

            assert :ok =
                     Membership.create_person(
                       %{
                         person_id: person_id,
                         name: person_name,
                         email_addresses: [%{email: email, is_primary: true}]
                       },
                       consistency: :strong
                     )

            assert %PersonProjection{} = person = Membership.get_person(person_id)
            remember_person(context, person_name, person)
        end
    end
  end

  defp put_person_email_if_missing(context, person_name, email) do
    case get_in(context, [:people, person_name]) do
      nil ->
        update_context_map(context, :people, person_name, %{email: email, name: person_name})

      _person ->
        context
    end
  end

  defp remember_person(context, person_name, %PersonProjection{} = person) do
    update_context_map(context, :people, person_name, %{
      person_id: person.person_id,
      name: person.name,
      email: person.email
    })
  end

  defp remember_active_membership(context, person_name, club_name) do
    club_id = fetch_club_id!(context, club_name)
    person = fetch_person!(context, person_name)
    membership_id = active_membership_id!(club_id, person.person_id)
    update_context_map(context, :memberships, {club_name, person_name}, membership_id)
  end

  defp sign_in_as(context, person_name) do
    sign_in_email(context, email_for_person(context, person_name))
  end

  defp sign_in_email(context, email) do
    normalized_email = Accounts.normalize_email(email)

    Map.put(context, :signed_in_identity, %{
      email: normalized_email,
      staff?: Accounts.staff_email?(normalized_email),
      active_clubs: Accounts.list_active_clubs_for_email(normalized_email)
    })
  end

  defp fetch_person!(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        Membership.get_person(person_id) || flunk("Expected #{person_name} to exist")

      %{email: email} ->
        Membership.get_person_by_email(email) ||
          flunk("Expected #{person_name} to exist with #{email}")

      _missing ->
        flunk("Expected #{person_name} to be known as a person")
    end
  end

  defp email_for_person(context, person_name) do
    case get_in(context, [:people, person_name, :email]) do
      email when is_binary(email) -> normalize_email!(email)
      _missing -> default_email_for(context, person_name)
    end
  end

  defp active_membership_count_by_email(club_id, email) do
    normalized_email = Accounts.normalize_email(email)

    MembershipProjection
    |> join(
      :inner,
      [membership],
      email_address in Memba.Membership.Projections.PersonEmailAddress,
      on: email_address.person_id == membership.person_id
    )
    |> where([membership, _email_address], membership.club_id == ^club_id)
    |> where([membership, _email_address], membership.active == true)
    |> where([_membership, email_address], email_address.normalized_email == ^normalized_email)
    |> Repo.aggregate(:count, :membership_id)
  end

  defp pending_invitation_count(club_id, email) do
    normalized_email = Accounts.normalize_email(email)

    ClubInvitation
    |> where([invitation], invitation.club_id == ^club_id)
    |> where([invitation], invitation.normalized_email == ^normalized_email)
    |> where([invitation], invitation.status == "pending")
    |> Repo.aggregate(:count, :invitation_id)
  end

  defp active_membership_id!(club_id, person_id) do
    active_membership_id(club_id, person_id) ||
      flunk("Expected active membership for #{person_id} in #{club_id}")
  end

  defp active_membership_id(club_id, person_id) do
    MembershipProjection
    |> where([membership], membership.club_id == ^club_id)
    |> where([membership], membership.person_id == ^person_id)
    |> where([membership], membership.active == true)
    |> select([membership], membership.membership_id)
    |> limit(1)
    |> Repo.one()
  end

  defp active_role_assignment?(club_id, membership_id, person_id, role_id) do
    RoleAssignment
    |> where([assignment], assignment.club_id == ^club_id)
    |> where([assignment], assignment.membership_id == ^membership_id)
    |> where([assignment], assignment.person_id == ^person_id)
    |> where([assignment], assignment.role_id == ^role_id)
    |> where([assignment], assignment.active == true)
    |> Repo.exists?()
  end

  defp fetch_club_id!(context, club_name) do
    case get_in(context, [:clubs, club_name]) do
      club_id when is_binary(club_id) -> club_id
      %{club_id: club_id} when is_binary(club_id) -> club_id
      _missing -> flunk("Expected #{club_name} to be known as a club")
    end
  end

  defp fetch_from_context!(context, collection_key, item_key) do
    context
    |> Map.get(collection_key, %{})
    |> Map.fetch(item_key)
    |> case do
      {:ok, value} -> value
      :error -> flunk("Expected #{inspect(item_key)} to be present in #{inspect(collection_key)}")
    end
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp sent_invitation_count(context, club_name, email) do
    get_in(context, [:sent_club_member_invitation_counts, {club_name, normalize_email!(email)}]) ||
      0
  end

  defp inferred_club_name(context) do
    case Map.keys(Map.get(context, :clubs, %{})) do
      [club_name] ->
        club_name

      _other ->
        case Map.get(context, :pending_profile_completion) do
          %{club_name: club_name} -> club_name
          _missing -> flunk("Expected exactly one club in the invitation scenario")
        end
    end
  end

  defp club_name(word_1, word_2, word_3), do: Enum.join([word_1, word_2, word_3], " ")

  defp normalize_email!(email), do: Accounts.normalize_email(email)

  defp staff_email_for(person_name), do: "#{String.downcase(person_name)}@memba.io"

  defp default_email_for(_context, "Pat"), do: staff_email_for("Pat")

  defp default_email_for(context, person_name),
    do: "#{email_local_part(person_name)}-#{scenario_email_suffix(context)}@example.test"

  defp staff_actor?(context, actor_name) do
    context
    |> email_for_person(actor_name)
    |> Accounts.staff_email?()
  end

  defp person_name_from_email(email) do
    email
    |> String.split("@", parts: 2)
    |> hd()
    |> String.split(~r/[^a-z0-9]+/i, trim: true)
    |> Enum.map_join(" ", fn part -> String.capitalize(String.downcase(part)) end)
    |> case do
      "" -> "Invitee"
      person_name -> person_name
    end
  end

  defp email_local_part(person_name) do
    person_name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, ".")
    |> String.trim(".")
  end

  defp scenario_slug(_context, "West Coast Paddlers"), do: "west-coast-paddlers"

  defp scenario_slug(context, club_name) do
    suffix = scenario_email_suffix(context)

    base =
      Slug.default_from_name(club_name)
      |> String.slice(0, Slug.max_length() - String.length(suffix) - 1)
      |> String.trim("-")

    "#{base}-#{suffix}"
  end

  defp scenario_email_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
