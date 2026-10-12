defmodule Memba.Membership.InvitationIssuanceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.AddMember
  alias Memba.Membership.ClubGroupQueries

  alias Memba.Membership.InvitationIssuanceWorkflow

  alias Memba.Membership.InvitationQueries
  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.{InviteClubMember, ResendClubMemberInvitation}
  alias Memba.Membership.InvitationIssuance
  alias Memba.Membership.InvitationToken

  test "preparation does not dispatch and adapter persists only the hash with caller consistency/returning" do
    club_id = ID.generate(:club)
    invitation_id = ID.generate(:club_invitation)

    assert {:ok, %InviteClubMember{} = command, token} =
             InvitationIssuance.prepare_invite(%{
               "club_id" => club_id,
               "email" => " Robin@Example.com ",
               "invitation_id" => invitation_id
             })

    assert command.invitation_id == invitation_id
    assert command.token_hash == InvitationToken.hash_token(token)
    refute command.token_hash == token
    assert nil == InvitationQueries.get(invitation_id)

    assert {:ok, %ExecutionResult{aggregate_uuid: ^invitation_id}} =
             CommandDispatch.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %{token_hash: hash} = InvitationQueries.get(invitation_id)
    assert hash == InvitationToken.hash_token(token)
  end

  test "repeat invite prepares a resend of the same club's pending invitation without dispatch" do
    club_id = ID.generate(:club)
    other_club_id = ID.generate(:club)
    invitation_id = ID.generate(:club_invitation)

    assert {:ok, %{invitation_token: original_token}} =
             InvitationIssuanceWorkflow.invite(
               %{club_id: club_id, invitation_id: invitation_id, email: "Robin@Example.com"},
               consistency: :strong
             )

    assert {:ok, %InviteClubMember{club_id: ^other_club_id}, _token} =
             InvitationIssuance.prepare_invite(%{
               club_id: other_club_id,
               email: "robin@example.com"
             })

    assert {:ok, %ResendClubMemberInvitation{} = command, token} =
             InvitationIssuance.prepare_invite(%{
               club_id: club_id,
               invitation_id: ID.generate(:club_invitation),
               email: " robin@EXAMPLE.com "
             })

    assert command.invitation_id == invitation_id
    refute token == original_token
    assert command.token_hash == InvitationToken.hash_token(token)

    assert %{resend_count: 0, token_hash: original_hash} =
             InvitationQueries.get(invitation_id)

    assert original_hash == InvitationToken.hash_token(original_token)

    assert {:ok, %ResendClubMemberInvitation{invitation_id: ^invitation_id}, _token} =
             InvitationIssuance.prepare_resend(%{club_id: club_id, email: "ROBIN@example.com"})

    assert {:error, :pending_invitation_not_found} =
             InvitationIssuance.prepare_resend(%{
               club_id: other_club_id,
               email: "robin@example.com"
             })
  end

  test "resend preparation retains missing and invalid pending invitation errors" do
    assert {:error, {:missing_required_attribute, :club_id}} =
             InvitationIssuance.prepare_resend(%{})

    assert {:error, :pending_invitation_not_found} =
             InvitationIssuance.prepare_resend(%{invitation_id: "not-an-invitation"})
  end

  test "invite/2 preserves Staff/system invitations without requiring a club-member actor" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              invitation_token: invitation_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvited{
                    invitation_id: ^invitation_id,
                    club_id: ^club_id,
                    email: "Robin@Example.COM",
                    normalized_email: "robin@example.com",
                    token_hash: token_hash
                  }
                ]
              }
            }} =
             InvitationIssuanceWorkflow.invite(
               %{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: " Robin@Example.COM "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert is_binary(invitation_token)
    refute invitation_token == token_hash
    assert InvitationToken.hash_token(invitation_token) == token_hash

    assert %ClubInvitationProjection{
             invitation_id: ^invitation_id,
             club_id: ^club_id,
             email: "Robin@Example.COM",
             normalized_email: "robin@example.com",
             token_hash: ^token_hash,
             status: "pending",
             resend_count: 0
           } = InvitationQueries.get(invitation_id)

    assert [] = ClubGroupQueries.list_active_members_of_club(club_id)
  end

  test "invite/2 rejects an active club member by normalized email" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    invitation_id = Memba.ID.generate(:club_invitation)

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
                       name: "Robin",
                       email_addresses: [
                         %{email: "robin@example.com", is_primary: true},
                         %{email: "Robin@Work.Example", is_primary: false}
                       ]
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: membership_id,
                       club_id: club_id,
                       person_id: person_id
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert {:error, :already_active_member} =
             InvitationIssuanceWorkflow.invite(
               %{invitation_id: invitation_id, club_id: club_id, email: " robin@work.example "},
               returning: :execution_result,
               consistency: :strong
             )

    assert is_nil(InvitationQueries.get(invitation_id))
  end

  test "invite/2 resends a pending invitation by normalized club email" do
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

    assert {:ok,
            %{
              invitation_id: ^original_invitation_id,
              invitation_token: second_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^original_invitation_id,
                events: [
                  %ClubMemberInvitationResent{
                    invitation_id: ^original_invitation_id,
                    token_hash: second_hash
                  }
                ]
              }
            }} =
             InvitationIssuanceWorkflow.invite(
               %{
                 invitation_id: duplicate_invitation_id,
                 club_id: club_id,
                 email: " robin@example.com "
               },
               returning: :execution_result,
               consistency: :strong
             )

    refute second_token == first_token
    refute second_hash == first_hash
    assert InvitationToken.hash_token(second_token) == second_hash

    assert is_nil(InvitationQueries.get(duplicate_invitation_id))

    assert %ClubInvitationProjection{
             invitation_id: ^original_invitation_id,
             normalized_email: "robin@example.com",
             token_hash: ^second_hash,
             resend_count: 1,
             status: "pending"
           } =
             InvitationQueries.get_pending_by_email(club_id, "ROBIN@example.com")
  end

  test "resend/2 rotates the token for the pending club email" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)

    assert {:ok, %{invitation_token: first_token}} =
             InvitationIssuanceWorkflow.invite(
               %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
               consistency: :strong
             )

    first_hash = InvitationToken.hash_token(first_token)

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              invitation_token: second_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationResent{
                    invitation_id: ^invitation_id,
                    token_hash: second_hash
                  }
                ]
              }
            }} =
             InvitationIssuanceWorkflow.resend(
               %{club_id: club_id, email: " ROBIN@example.com "},
               returning: :execution_result,
               consistency: :strong
             )

    refute second_token == first_token
    refute second_hash == first_hash
    assert InvitationToken.hash_token(second_token) == second_hash

    assert %ClubInvitationProjection{
             invitation_id: ^invitation_id,
             token_hash: ^second_hash,
             resend_count: 1,
             status: "pending"
           } =
             InvitationQueries.get_pending_by_email(club_id, "robin@example.com")
  end
end
