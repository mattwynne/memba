defmodule Memba.Membership.ClubMemberInvitationLifecycleTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Roles

  describe "club member invitation lifecycle application API" do
    test "pending invitation creation stores only the invitation before profile completion" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)

      assert {:ok, %{invitation_id: ^invitation_id, invitation_token: invitation_token}} =
               Membership.invite_club_member(
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
             } = Membership.get_club_member_invitation(invitation_id)

      assert %ClubInvitationProjection{invitation_id: ^invitation_id, status: "pending"} =
               Membership.get_club_member_invitation_by_token(invitation_token)

      assert is_nil(Membership.get_person_by_email("robin@example.com"))
      assert [] = Membership.list_active_members_of_club(club_id)
    end

    test "duplicate active member invitation is blocked using normalized email" do
      club_id = Memba.ID.generate(:club)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)
      invitation_id = Memba.ID.generate(:club_invitation)

      assert :ok =
               Membership.create_person(
                 %{
                   person_id: person_id,
                   name: "Robin",
                   email_addresses: [
                     %{email: "robin@example.com", is_primary: true},
                     %{email: "Robin@Work.Example", is_primary: false}
                   ]
                 },
                 consistency: :strong
               )

      assert :ok =
               Membership.add_member(
                 %{membership_id: membership_id, club_id: club_id, person_id: person_id},
                 consistency: :strong
               )

      assert {:error, :already_active_member} =
               Membership.invite_club_member(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   email: " robin@work.example "
                 },
                 consistency: :strong
               )

      assert is_nil(Membership.get_club_member_invitation(invitation_id))

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               Membership.list_active_members_of_club(club_id)
    end

    test "duplicate pending invitation resends and keeps a single pending invitation" do
      club_id = Memba.ID.generate(:club)
      original_invitation_id = Memba.ID.generate(:club_invitation)
      duplicate_invitation_id = Memba.ID.generate(:club_invitation)

      assert {:ok, %{invitation_token: first_token}} =
               Membership.invite_club_member(
                 %{
                   invitation_id: original_invitation_id,
                   club_id: club_id,
                   email: "Robin@Example.COM"
                 },
                 consistency: :strong
               )

      first_hash = InvitationToken.hash_token(first_token)

      assert {:ok, %{invitation_id: ^original_invitation_id, invitation_token: second_token}} =
               Membership.invite_club_member(
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
      assert is_nil(Membership.get_club_member_invitation(duplicate_invitation_id))

      assert %ClubInvitationProjection{
               invitation_id: ^original_invitation_id,
               normalized_email: "robin@example.com",
               token_hash: ^second_hash,
               status: "pending",
               resend_count: 1
             } =
               Membership.get_pending_club_member_invitation_by_email(
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

    test "existing complete person accepts an invitation and becomes an ordinary active member" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      assert :ok =
               Membership.create_person(
                 %{person_id: person_id, name: "Alice", email: "Alice@Example.COM"},
                 consistency: :strong
               )

      assert {:ok, %{invitation_token: _invitation_token}} =
               Membership.invite_club_member(
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
               Membership.accept_club_member_invitation_for_existing_person(
                 %{
                   invitation_id: invitation_id,
                   person_id: person_id,
                   membership_id: membership_id
                 },
                 consistency: :strong
               )

      assert %PersonProjection{person_id: ^person_id, name: "Alice"} =
               Membership.get_person_by_email("ALICE@example.com")

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               Membership.list_active_members_of_club(club_id)

      assert %ClubInvitationProjection{
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = Membership.get_club_member_invitation(invitation_id)
    end

    test "unknown invitee profile completion creates the person, membership, and acceptance" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      assert {:ok, %{invitation_token: _invitation_token}} =
               Membership.invite_club_member(
                 %{invitation_id: invitation_id, club_id: club_id, email: " Robin@Example.COM "},
                 consistency: :strong
               )

      assert is_nil(Membership.get_person_by_email("robin@example.com"))
      assert [] = Membership.list_active_members_of_club(club_id)

      assert {:ok,
              %{
                invitation_id: ^invitation_id,
                club_id: ^club_id,
                person_id: ^person_id,
                membership_id: ^membership_id
              }} =
               Membership.complete_invited_club_member_profile(
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
             } = Membership.get_person_by_email("robin@example.com")

      assert [
               %{
                 email: "Robin@Example.COM",
                 normalized_email: "robin@example.com",
                 primary?: true
               }
             ] =
               Membership.list_person_email_addresses(person_id)

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               Membership.list_active_members_of_club(club_id)

      assert %ClubInvitationProjection{
               status: "accepted",
               accepted_person_id: ^person_id,
               accepted_membership_id: ^membership_id
             } = Membership.get_club_member_invitation(invitation_id)
    end

    test "abandoned profile completion leaves invitation pending and token reusable" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      assert {:ok, %{invitation_token: invitation_token}} =
               Membership.invite_club_member(
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
             } = Membership.get_club_member_invitation_by_token(invitation_token)

      assert is_nil(Membership.get_person_by_email("robin@example.com"))
      assert [] = Membership.list_active_members_of_club(club_id)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               token_hash: ^token_hash,
               status: "pending"
             } = Membership.get_club_member_invitation_by_token(invitation_token)

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               Membership.complete_invited_club_member_profile(
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
             } = Membership.get_club_member_invitation_by_token(invitation_token)
    end

    test "accepted invitation token can be reused for lookup without duplicate membership creation" do
      club_id = Memba.ID.generate(:club)
      invitation_id = Memba.ID.generate(:club_invitation)
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)
      duplicate_person_id = Memba.ID.generate(:person)
      duplicate_membership_id = Memba.ID.generate(:membership)

      assert {:ok, %{invitation_token: invitation_token}} =
               Membership.invite_club_member(
                 %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
                 consistency: :strong
               )

      assert {:ok, %{person_id: ^person_id, membership_id: ^membership_id}} =
               Membership.complete_invited_club_member_profile(
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
             } = Membership.get_club_member_invitation_by_token(invitation_token)

      assert {:error, :already_accepted} =
               Membership.complete_invited_club_member_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: duplicate_person_id,
                   membership_id: duplicate_membership_id,
                   name: "Duplicate Robin"
                 },
                 consistency: :strong
               )

      assert [%{id: ^person_id, membership_id: ^membership_id}] =
               Membership.list_active_members_of_club(club_id)

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

      assert is_nil(Membership.get_person(duplicate_person_id))
      assert is_nil(Repo.get(MembershipProjection, duplicate_membership_id))
    end

    test "membership admin invitations delegate to the shared pending, resend, token, and profile-completion lifecycle" do
      club_id = Memba.ID.generate(:club)
      actor_person_id = Memba.ID.generate(:person)
      actor_membership_id = Memba.ID.generate(:membership)
      invitation_id = Memba.ID.generate(:club_invitation)
      duplicate_invitation_id = Memba.ID.generate(:club_invitation)
      invited_person_id = Memba.ID.generate(:person)
      invited_membership_id = Memba.ID.generate(:membership)

      create_club!(club_id)
      create_person!(actor_person_id, "Robin Admin", "robin@example.com")
      add_member!(actor_membership_id, club_id, actor_person_id)
      assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

      assert {:ok, %{invitation_id: ^invitation_id, invitation_token: first_token}} =
               Membership.invite_club_member_as_club_member(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   actor_person_id: actor_person_id,
                   email: " Dana@Example.COM "
                 },
                 consistency: :strong
               )

      first_hash = InvitationToken.hash_token(first_token)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               club_id: ^club_id,
               email: "Dana@Example.COM",
               normalized_email: "dana@example.com",
               token_hash: ^first_hash,
               status: "pending",
               resend_count: 0
             } = Membership.get_club_member_invitation_by_token(first_token)

      assert {:ok, %{invitation_id: ^invitation_id, invitation_token: second_token}} =
               Membership.invite_club_member_as_club_member(
                 %{
                   invitation_id: duplicate_invitation_id,
                   club_id: club_id,
                   actor_person_id: actor_person_id,
                   email: "dana@example.com"
                 },
                 consistency: :strong
               )

      second_hash = InvitationToken.hash_token(second_token)
      refute second_token == first_token
      refute second_hash == first_hash
      assert is_nil(Membership.get_club_member_invitation(duplicate_invitation_id))
      assert is_nil(Membership.get_club_member_invitation_by_token(first_token))

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               token_hash: ^second_hash,
               status: "pending",
               resend_count: 1
             } = Membership.get_club_member_invitation_by_token(second_token)

      assert {:ok,
              %{
                invitation_id: ^invitation_id,
                club_id: ^club_id,
                person_id: ^invited_person_id,
                membership_id: ^invited_membership_id
              }} =
               Membership.complete_invited_club_member_profile(
                 %{
                   invitation_id: invitation_id,
                   person_id: invited_person_id,
                   membership_id: invited_membership_id,
                   name: " Dana Example "
                 },
                 consistency: :strong
               )

      assert %PersonProjection{
               person_id: ^invited_person_id,
               name: "Dana Example",
               email: "Dana@Example.COM"
             } = Membership.get_person_by_email("dana@example.com")

      assert Enum.any?(Membership.list_active_members_of_club(club_id), fn member ->
               match?(%{id: ^invited_person_id, membership_id: ^invited_membership_id}, member)
             end)

      assert %ClubInvitationProjection{
               invitation_id: ^invitation_id,
               status: "accepted",
               accepted_person_id: ^invited_person_id,
               accepted_membership_id: ^invited_membership_id
             } = Membership.get_club_member_invitation_by_token(second_token)
    end

    test "membership admin invitations reuse the active-member duplicate rule" do
      club_id = Memba.ID.generate(:club)
      actor_person_id = Memba.ID.generate(:person)
      actor_membership_id = Memba.ID.generate(:membership)
      target_person_id = Memba.ID.generate(:person)
      target_membership_id = Memba.ID.generate(:membership)
      invitation_id = Memba.ID.generate(:club_invitation)

      create_club!(club_id)
      create_person!(actor_person_id, "Robin Admin", "robin@example.com")
      add_member!(actor_membership_id, club_id, actor_person_id)
      assign_membership_administrator!(club_id, actor_membership_id, actor_person_id)

      assert :ok =
               Membership.create_person(
                 %{
                   person_id: target_person_id,
                   name: "Alice Existing",
                   email_addresses: [
                     %{email: "alice@example.com", is_primary: true},
                     %{email: "Alice@Work.Example", is_primary: false}
                   ]
                 },
                 consistency: :strong
               )

      add_member!(target_membership_id, club_id, target_person_id)

      assert {:error, :already_active_member} =
               Membership.invite_club_member_as_club_member(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   actor_person_id: actor_person_id,
                   email: " alice@work.example "
                 },
                 consistency: :strong
               )

      assert is_nil(Membership.get_club_member_invitation(invitation_id))
      assert Membership.active_member_of_club_by_email?(club_id, "ALICE@WORK.EXAMPLE")
    end

    test "ordinary members cannot use the member-facing invitation service" do
      club_id = Memba.ID.generate(:club)
      actor_person_id = Memba.ID.generate(:person)
      actor_membership_id = Memba.ID.generate(:membership)
      invitation_id = Memba.ID.generate(:club_invitation)

      create_club!(club_id)
      create_person!(actor_person_id, "Alice Member", "alice@example.com")
      add_member!(actor_membership_id, club_id, actor_person_id)

      refute Membership.person_has_club_permission?(
               club_id,
               actor_person_id,
               Permissions.club_manage_members()
             )

      assert {:error, :unauthorized} =
               Membership.invite_club_member_as_club_member(
                 %{
                   invitation_id: invitation_id,
                   club_id: club_id,
                   actor_person_id: actor_person_id,
                   email: "dana@example.com"
                 },
                 consistency: :strong
               )

      assert is_nil(Membership.get_club_member_invitation(invitation_id))

      assert is_nil(
               Membership.get_pending_club_member_invitation_by_email(club_id, "dana@example.com")
             )
    end
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
               consistency: :strong
             )
  end

  defp create_person!(person_id, name, email) do
    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )
  end

  defp add_member!(membership_id, club_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )
  end

  defp assign_membership_administrator!(club_id, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )

    assert Membership.person_has_club_permission?(
             club_id,
             person_id,
             Permissions.club_manage_members()
           )
  end
end
