defmodule Memba.Membership.ClubMemberInvitationLifecycleTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.MembershipQueries

  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.InvitationAcceptance
  alias Memba.Membership.InvitationIssuanceWorkflow
  alias Memba.Membership.InvitationQueries
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.PermissionQueries
  alias Memba.Membership.Permissions
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.Roles

  describe "club member invitation lifecycle application API" do
    test "invitation reads reject malformed inputs and keep club and token scope" do
      club_id = Memba.ID.generate(:club)
      other_club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)

      assert {:ok, %{invitation_token: token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "Robin@Example.COM"},
                 consistency: :strong
               )

      assert %ClubInvitationProjection{invitation_id: ^invitation_id} =
               InvitationQueries.get_pending_by_email(
                 club_id,
                 " robin@EXAMPLE.com "
               )

      for invalid_id <- [nil, "not-an-id", other_club_id] do
        assert is_nil(InvitationQueries.get(invalid_id))
      end

      for invalid_email <- [nil, "", "not-an-email"] do
        assert is_nil(InvitationQueries.get_pending_by_email(club_id, invalid_email))
      end

      assert is_nil(
               InvitationQueries.get_pending_by_email(
                 other_club_id,
                 "robin@example.com"
               )
             )

      assert is_nil(InvitationQueries.get_pending_by_email(nil, "robin@example.com"))

      assert is_nil(InvitationQueries.get_by_token(nil))
      assert is_nil(InvitationQueries.get_by_token("wrong-token"))

      assert %ClubInvitationProjection{invitation_id: ^invitation_id} =
               InvitationQueries.get_by_token(token)
    end

    test "pending invitation creation stores only the invitation before profile completion" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)

      assert {:ok, %{invitation_id: ^invitation_id, invitation_token: invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   email: " Robin@Example.COM "
                 },
                 consistency: :strong
               )

      token_hash = InvitationToken.hash_token(invitation_token)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               club_id: ^club_id,
               email: "Robin@Example.COM",
               normalized_email: "robin@example.com",
               token_hash: ^token_hash,
               status: "pending",
               accepted_person_id: nil,
               accepted_membership_id: nil,
               resend_count: 0
             } = InvitationQueries.get(invitation_id)

      assert %ClubInvitationProjection{invitation_id: ^invitation_id, status: "pending"} =
               InvitationQueries.get_by_token(invitation_token)

      assert is_nil(PersonQueries.get_person_by_email("robin@example.com"))
      assert [] = ClubGroupQueries.list_active_members_of_club(club_id)
    end

    test "duplicate active member invitation is blocked using normalized email" do
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)
      invitation_id = Memba.ID.generate(:club_invitation)

      create_club!(club_id)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Robin",
                 email_addresses: [
                   %{email: "robin@example.com", is_primary: true},
                   %{email: "Robin@Work.Example", is_primary: false}
                 ]
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, member_command} =
               AddMember.prepare(%{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               })

      assert :ok = CommandDispatch.dispatch(member_command, consistency: :strong)

      assert {:error, :already_active_member} =
               InvitationIssuanceWorkflow.invite(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   email: " robin@work.example "
                 },
                 consistency: :strong
               )

      assert is_nil(InvitationQueries.get(invitation_id))

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               ClubGroupQueries.list_active_members_of_club(club_id)
    end

    test "duplicate pending invitation resends and keeps a single pending invitation" do
      club_id = Memba.ID.generate(:club)
      original_invitation_id = Memba.ID.generate(:club_invitation)
      duplicate_invitation_id = Memba.ID.generate(:club_invitation)

      assert {:ok, %{invitation_token: first_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{
                   invitation_id: original_invitation_id,
                   club_id: club_id,
                   email: "Robin@Example.COM"
                 },
                 consistency: :strong
               )

      first_hash = InvitationToken.hash_token(first_token)

      assert {:ok, %{invitation_id: ^original_invitation_id, invitation_token: second_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{
                   invitation_id: duplicate_invitation_id,
                   club_id: club_id,
                   email: " robin@example.com "
                 },
                 consistency: :strong
               )

      second_hash = InvitationToken.hash_token(second_token)

      refute second_token == first_token
      refute second_hash == first_hash
      assert is_nil(InvitationQueries.get(duplicate_invitation_id))

      assert %ClubInvitationProjection{
               invitation_id: ^original_invitation_id,
               normalized_email: "robin@example.com",
               token_hash: ^second_hash,
               status: "pending",
               resend_count: 1
             } =
               InvitationQueries.get_pending_by_email(
                 club_id,
                 "ROBIN@example.com"
               )

      assert 1 ==
               Repo.aggregate(
                 from(invitation in ClubInvitationProjection,
                   where:
                     invitation.club_id == ^club_id and
                       invitation.normalized_email == "robin@example.com"
                 ),
                 :count
               )
    end

    test "existing complete person accepts the first invitation and becomes Admin" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Alice",
                 email: "Alice@Example.COM"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: " alice@example.com "},
                 consistency: :strong
               )

      assert {:ok,
              %{
                invitation_id: ^invitation_id,
                club_id: ^club_id,
                person_id: ^person_id,
                membership_id: ^membership_id
              }} =
               InvitationAcceptance.accept_existing(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id,
                   membership_id: membership_id
                 },
                 consistency: :strong
               )

      assert %PersonProjection{person_id: ^person_id, name: "Alice"} =
               PersonQueries.get_person_by_email("ALICE@example.com")

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               ClubGroupQueries.list_active_members_of_club(club_id)

      assert PermissionQueries.has_permission?(
               club_id,
               person_id,
               Permissions.club_manage_members()
             )

      assert member_permission?(
               club_id,
               person_id,
               Permissions.club_manage_members()
             )

      assert %ClubInvitationProjection{
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = InvitationQueries.get(invitation_id)
    end

    test "unknown first invitee profile completion creates the person, Admin membership, and acceptance" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: " Robin@Example.COM "},
                 consistency: :strong
               )

      assert is_nil(PersonQueries.get_person_by_email("robin@example.com"))
      assert [] = ClubGroupQueries.list_active_members_of_club(club_id)

      assert {:ok,
              %{
                invitation_id: ^invitation_id,
                club_id: ^club_id,
                person_id: ^person_id,
                membership_id: ^membership_id
              }} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id,
                   membership_id: membership_id,
                   name: " Robin "
                 },
                 consistency: :strong
               )

      assert %PersonProjection{
               person_id: ^person_id,
               name: "Robin",
               email: "Robin@Example.COM"
             } = PersonQueries.get_person_by_email("robin@example.com")

      assert [
               %{
                 email: "Robin@Example.COM",
                 normalized_email: "robin@example.com",
                 primary?: true
               }
             ] =
               PersonQueries.list_person_email_addresses(person_id)

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               ClubGroupQueries.list_active_members_of_club(club_id)

      assert PermissionQueries.has_permission?(
               club_id,
               person_id,
               Permissions.club_manage_members()
             )

      assert member_permission?(
               club_id,
               person_id,
               Permissions.club_manage_members()
             )

      assert %ClubInvitationProjection{
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = InvitationQueries.get(invitation_id)
    end

    test "abandoned profile completion leaves invitation pending and token reusable" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, %{invitation_token: invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      token_hash = InvitationToken.hash_token(invitation_token)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               token_hash: ^token_hash,
               status: "pending",
               accepted_person_id: nil,
               accepted_membership_id: nil
             } = InvitationQueries.get_by_token(invitation_token)

      assert is_nil(PersonQueries.get_person_by_email("robin@example.com"))
      assert [] = ClubGroupQueries.list_active_members_of_club(club_id)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               token_hash: ^token_hash,
               status: "pending"
             } = InvitationQueries.get_by_token(invitation_token)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id,
                   membership_id: membership_id,
                   name: "Robin"
                 },
                 consistency: :strong
               )

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = InvitationQueries.get_by_token(invitation_token)
    end

    test "profile completion retries after person creation with deterministic identities" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = deterministic_invitation_person_id(invitation_id)
      membership_id = deterministic_invitation_membership_id(invitation_id)

      create_club!(club_id)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "Robin@Example.COM"},
                 consistency: :strong
               )

      assert {:error, :simulated_after_person_created} =
               InvitationAcceptance.complete_profile(
                 %{invitation_id: invitation_id, name: "Robin"},
                 after_invitation_person_created: fn ->
                   {:error, :simulated_after_person_created}
                 end
               )

      assert %PersonProjection{person_id: ^person_id, name: "Robin"} =
               PersonQueries.get_person_by_email("robin@example.com")

      assert is_nil(Repo.get(MembershipProjection, membership_id))

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   name: "Robin"
                 },
                 []
               )

      assert one_active_membership!(club_id, person_id).membership_id == membership_id
      assert admin_assignment_count(club_id, membership_id) == 1
    end

    test "profile completion retries after membership activation" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = deterministic_invitation_person_id(invitation_id)
      membership_id = deterministic_invitation_membership_id(invitation_id)

      create_club!(club_id)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "Robin@Example.COM"},
                 consistency: :strong
               )

      assert {:error, :simulated_after_membership_added} =
               InvitationAcceptance.complete_profile(
                 %{invitation_id: invitation_id, name: "Robin"},
                 consistency: :strong,
                 after_invitation_membership_added: fn ->
                   {:error, :simulated_after_membership_added}
                 end
               )

      assert one_active_membership!(club_id, person_id).membership_id == membership_id

      assert %Memba.Membership.Projections.ClubInvitation{status: "pending"} =
               InvitationQueries.get(invitation_id)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{invitation_id: invitation_id, name: "Robin"},
                 consistency: :strong
               )

      assert admin_assignment_count(club_id, membership_id) == 1
    end

    test "invitation acceptance retries after membership activation for existing people" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = deterministic_invitation_membership_id(invitation_id)

      create_club!(club_id)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "alice@example.com"},
                 consistency: :strong
               )

      assert {:error, :simulated_after_membership_added} =
               InvitationAcceptance.accept_existing(
                 %{invitation_id: invitation_id, person_id: person_id},
                 after_invitation_membership_added: fn ->
                   {:error, :simulated_after_membership_added}
                 end
               )

      assert one_active_membership!(club_id, person_id).membership_id == membership_id

      assert %Memba.Membership.Projections.ClubInvitation{status: "pending"} =
               InvitationQueries.get(invitation_id)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.accept_existing(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id
                 },
                 []
               )

      assert admin_assignment_count(club_id, membership_id) == 1

      assert %Memba.Membership.Projections.ClubInvitation{status: "accepted"} =
               InvitationQueries.get(invitation_id)
    end

    test "profile completion recovers pre-existing non-deterministic person and membership IDs" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Robin",
                 email: "robin@example.com"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, member_command} =
               AddMember.prepare(%{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               })

      assert :ok = CommandDispatch.dispatch(member_command, consistency: :strong)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   name: "Robin"
                 },
                 []
               )

      assert one_active_membership!(club_id, person_id).membership_id == membership_id
      assert admin_assignment_count(club_id, membership_id) == 1
    end

    test "existing-person acceptance recovers a pre-existing non-deterministic membership ID" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, %{invitation_token: _invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "alice@example.com"},
                 consistency: :strong
               )

      assert {:ok, member_command} =
               AddMember.prepare(%{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               })

      assert :ok = CommandDispatch.dispatch(member_command, consistency: :strong)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.accept_existing(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id
                 },
                 []
               )

      assert one_active_membership!(club_id, person_id).membership_id == membership_id
    end

    test "profile retry rejects different explicit IDs after person and membership steps" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = deterministic_invitation_person_id(invitation_id)
      membership_id = deterministic_invitation_membership_id(invitation_id)

      create_club!(club_id)

      assert {:ok, %{invitation_token: token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      assert {:error, :paused} =
               InvitationAcceptance.complete_profile(
                 %{invitation_id: invitation_id, name: "Robin"},
                 after_invitation_membership_added: fn -> {:error, :paused} end
               )

      assert {:error, :invitation_person_mismatch} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   name: "Robin",
                   person_id: Memba.ID.generate(:person)
                 },
                 []
               )

      assert {:error, :invitation_membership_mismatch} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   name: "Robin",
                   membership_id: Memba.ID.generate(:membership)
                 },
                 []
               )

      assert %ClubInvitationProjection{status: "pending"} =
               InvitationQueries.get_by_token(token)

      assert one_active_membership!(club_id, person_id).membership_id == membership_id

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   name: "Robin"
                 },
                 []
               )

      assert admin_assignment_count(club_id, membership_id) == 1
    end

    test "existing-person acceptance refuses a person without the invited email" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)

      create_club!(club_id)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Other",
                 email: "other@example.com"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, %{invitation_token: token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      assert {:error, :invitation_email_mismatch} =
               InvitationAcceptance.accept_existing(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id
                 },
                 []
               )

      assert [] = ClubGroupQueries.list_active_members_of_club(club_id)

      assert %ClubInvitationProjection{status: "pending"} =
               InvitationQueries.get_by_token(token)
    end

    test "recovered membership belongs to the invited club, not another club" do
      invited_club_id = Memba.ID.generate(:club)
      other_club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      other_membership_id = Memba.ID.generate(:membership)
      invited_membership_id = deterministic_invitation_membership_id(invitation_id)

      create_club!(invited_club_id)

      assert {:ok, club_command} =
               ClubCommands.prepare_create(
                 membership_club_attrs(club_id: other_club_id, name: "Other Club")
               )

      assert :ok = CommandDispatch.dispatch(club_command, consistency: :strong)

      assert {:ok, person_command} =
               PersonCommands.prepare_create(%{
                 person_id: person_id,
                 name: "Robin",
                 email: "robin@example.com"
               })

      assert :ok = CommandDispatch.dispatch(person_command, consistency: :strong)

      assert {:ok, member_command} =
               AddMember.prepare(%{
                 membership_id: other_membership_id,
                 club_id: other_club_id,
                 person_id: person_id
               })

      assert :ok = CommandDispatch.dispatch(member_command, consistency: :strong)

      assert {:ok, _invitation} =
               InvitationIssuanceWorkflow.invite(
                 %{
                   invitation_id: invitation_id,
                   club_id: invited_club_id,
                   email: "robin@example.com"
                 },
                 consistency: :strong
               )

      assert {:ok, %{membership_id: ^invited_membership_id}} =
               InvitationAcceptance.accept_existing(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id
                 },
                 []
               )

      assert one_active_membership!(invited_club_id, person_id).membership_id ==
               invited_membership_id

      assert one_active_membership!(other_club_id, person_id).membership_id == other_membership_id
    end

    test "accepted invitation token can be reused for lookup without duplicate membership creation" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)
      duplicate_person_id = Memba.ID.generate(:person)
      duplicate_membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)

      assert {:ok, %{invitation_token: invitation_token}} =
               InvitationIssuanceWorkflow.invite(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id,
                   membership_id: membership_id,
                   name: "Robin"
                 },
                 consistency: :strong
               )

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = InvitationQueries.get_by_token(invitation_token)

      assert {:error, :already_accepted} =
               InvitationAcceptance.complete_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: duplicate_person_id,
                   membership_id: duplicate_membership_id,
                   name: "Duplicate Robin"
                 },
                 consistency: :strong
               )

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               ClubGroupQueries.list_active_members_of_club(club_id)

      assert 1 ==
               Repo.aggregate(
                 from(membership in MembershipProjection,
                   where:
                     membership.club_id == ^club_id and
                       membership.person_id == ^person_id and
                       membership.active == true
                 ),
                 :count
               )

      assert is_nil(PersonQueries.get_person(duplicate_person_id))
      assert is_nil(Repo.get(MembershipProjection, duplicate_membership_id))
    end
  end

  defp deterministic_invitation_person_id(invitation_id) do
    Memba.ID.deterministic(:person, ["club_member_invitation_person", invitation_id])
  end

  defp deterministic_invitation_membership_id(invitation_id) do
    Memba.ID.deterministic(:membership, ["club_member_invitation_membership", invitation_id])
  end

  defp one_active_membership!(club_id, person_id) do
    assert [membership] =
             Repo.all(
               from(membership in MembershipProjection,
                 where: membership.club_id == ^club_id,
                 where: membership.person_id == ^person_id,
                 where: membership.active == true
               )
             )

    membership
  end

  defp admin_assignment_count(club_id, membership_id) do
    Repo.aggregate(
      from(assignment in RoleAssignment,
        where: assignment.club_id == ^club_id,
        where: assignment.membership_id == ^membership_id,
        where: assignment.role_id == ^Roles.membership_administrator_role_id(club_id),
        where: assignment.active == true
      ),
      :count
    )
  end

  defp create_club!(club_id) do
    assert {:ok, club_command} =
             ClubCommands.prepare_create(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club")
             )

    assert :ok = CommandDispatch.dispatch(club_command, consistency: :strong)
  end

  defp member_permission?(club_id, person_id, permission) do
    Repo.exists?(
      from(member_permission in MemberPermission,
        where: member_permission.club_id == ^club_id,
        where: member_permission.person_id == ^person_id,
        where: member_permission.permission == ^permission
      )
    )
  end

  test "accept_existing/2 returns membership and acceptance execution results" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Alice",
                       email: "Alice@Example.COM"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:ok, %{invitation_token: _token}} =
             InvitationIssuanceWorkflow.invite(
               %{invitation_id: invitation_id, club_id: club_id, email: " alice@example.com "},
               consistency: :strong
             )

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              club_id: ^club_id,
              person_id: ^person_id,
              membership_id: ^membership_id,
              membership_execution_result: %ExecutionResult{
                aggregate_uuid: ^club_id,
                events: [
                  %ClubMemberAdded{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id
                  },
                  %ClubRoleAssignedToMember{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id,
                    assignment_source: "automatic_first_club_member"
                  }
                ]
              },
              invitation_execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationAccepted{
                    invitation_id: ^invitation_id,
                    person_id: ^person_id,
                    membership_id: ^membership_id
                  }
                ]
              }
            }} =
             InvitationAcceptance.accept_existing(
               %{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert MembershipQueries.active_member_of_club?(club_id, person_id)

    assert %ClubInvitationProjection{
             status: "accepted",
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = InvitationQueries.get(invitation_id)
  end

  test "complete_profile/2 returns person, membership, and acceptance execution results" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:ok, %{invitation_token: _token}} =
             InvitationIssuanceWorkflow.invite(
               %{invitation_id: invitation_id, club_id: club_id, email: " Robin@Example.COM "},
               consistency: :strong
             )

    assert is_nil(PersonQueries.get_person(person_id))

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              club_id: ^club_id,
              person_id: ^person_id,
              membership_id: ^membership_id,
              person_execution_result: %ExecutionResult{
                aggregate_uuid: ^person_id,
                events: [
                  %PersonCreated{
                    person_id: ^person_id,
                    name: "Robin"
                  },
                  %PersonEmailAddressesReplaced{
                    person_id: ^person_id,
                    primary_email: "Robin@Example.COM"
                  }
                ]
              },
              membership_execution_result: %ExecutionResult{
                aggregate_uuid: ^club_id,
                events: [
                  %ClubMemberAdded{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id
                  },
                  %ClubRoleAssignedToMember{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id,
                    assignment_source: "automatic_first_club_member"
                  }
                ]
              },
              invitation_execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationAccepted{
                    invitation_id: ^invitation_id,
                    person_id: ^person_id,
                    membership_id: ^membership_id
                  }
                ]
              }
            }} =
             InvitationAcceptance.complete_profile(
               %{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id,
                 name: " Robin "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             name: "Robin",
             email: "Robin@Example.COM"
           } = PersonQueries.get_person(person_id)

    assert [%{email: "Robin@Example.COM", normalized_email: "robin@example.com", primary?: true}] =
             PersonQueries.list_person_email_addresses(person_id)

    assert %MembershipProjection{
             membership_id: ^membership_id,
             club_id: ^club_id,
             person_id: ^person_id,
             active: true
           } = Repo.get(MembershipProjection, membership_id)

    assert %ClubInvitationProjection{
             status: "accepted",
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = InvitationQueries.get(invitation_id)
  end
end
