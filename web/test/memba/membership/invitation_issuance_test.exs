defmodule Memba.Membership.InvitationIssuanceTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership
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
    assert nil == Membership.get_club_member_invitation(invitation_id)

    assert {:ok, %ExecutionResult{aggregate_uuid: ^invitation_id}} =
             CommandDispatch.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %{token_hash: hash} = Membership.get_club_member_invitation(invitation_id)
    assert hash == InvitationToken.hash_token(token)
  end

  test "repeat invite prepares a resend of the same club's pending invitation without dispatch" do
    club_id = ID.generate(:club)
    other_club_id = ID.generate(:club)
    invitation_id = ID.generate(:club_invitation)

    assert {:ok, %{invitation_token: original_token}} =
             Membership.invite_club_member(
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
             Membership.get_club_member_invitation(invitation_id)

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
end
