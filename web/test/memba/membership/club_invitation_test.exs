defmodule Memba.Membership.ClubInvitationTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.ClubInvitation
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.InvitationToken

  describe "execute/2 InviteClubMember" do
    test "emits ClubMemberInvited using the caller-supplied UUID identity" do
      invitation_id = Memba.ID.generate(:club_invitation)
      club_id = Memba.ID.generate(:club)
      token_hash = token_hash("invite")

      command = %InviteClubMember{
        invitation_id: invitation_id,
        club_id: club_id,
        email: " Robin@Example.COM ",
        token_hash: token_hash
      }

      assert %ClubMemberInvited{
               invitation_id: ^invitation_id,
               club_id: ^club_id,
               email: "Robin@Example.COM",
               normalized_email: "robin@example.com",
               token_hash: ^token_hash
             } = ClubInvitation.execute(%ClubInvitation{}, command)
    end

    test "rejects invalid identifiers, email, and token hash" do
      assert {:error, :invalid_invitation_id} =
               ClubInvitation.execute(%ClubInvitation{}, %InviteClubMember{
                 invitation_id: "not-an-invitation-id",
                 club_id: Memba.ID.generate(:club),
                 email: "robin@example.com",
                 token_hash: token_hash("invite")
               })

      assert {:error, :invalid_club_id} =
               ClubInvitation.execute(%ClubInvitation{}, %InviteClubMember{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 club_id: nil,
                 email: "robin@example.com",
                 token_hash: token_hash("invite")
               })

      assert {:error, :invalid_email} =
               ClubInvitation.execute(%ClubInvitation{}, %InviteClubMember{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 club_id: Memba.ID.generate(:club),
                 email: "not-an-email",
                 token_hash: token_hash("invite")
               })

      assert {:error, :invalid_token_hash} =
               ClubInvitation.execute(%ClubInvitation{}, %InviteClubMember{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 club_id: Memba.ID.generate(:club),
                 email: "robin@example.com",
                 token_hash: "not-a-hash"
               })
    end

    test "rejects creating the same invitation aggregate twice" do
      invitation = pending_invitation()

      assert {:error, :already_pending} =
               ClubInvitation.execute(invitation, %InviteClubMember{
                 invitation_id: invitation.invitation_id,
                 club_id: invitation.club_id,
                 email: invitation.email,
                 token_hash: token_hash("new-token")
               })
    end
  end

  describe "execute/2 ResendClubMemberInvitation" do
    test "rotates the token hash for a pending invitation" do
      invitation = pending_invitation()
      token_hash = token_hash("resend")

      assert %ClubMemberInvitationResent{
               invitation_id: invitation_id,
               token_hash: ^token_hash
             } =
               ClubInvitation.execute(invitation, %ResendClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 token_hash: token_hash
               })

      assert invitation_id == invitation.invitation_id
    end

    test "rejects missing, accepted, mismatched, or malformed resends" do
      assert {:error, :not_found} =
               ClubInvitation.execute(%ClubInvitation{}, %ResendClubMemberInvitation{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 token_hash: token_hash("resend")
               })

      assert {:error, :invitation_id_mismatch} =
               ClubInvitation.execute(pending_invitation(), %ResendClubMemberInvitation{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 token_hash: token_hash("resend")
               })

      invitation = pending_invitation()

      assert {:error, :invalid_token_hash} =
               ClubInvitation.execute(invitation, %ResendClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 token_hash: "not-a-hash"
               })

      invitation = accepted_invitation()

      assert {:error, :already_accepted} =
               ClubInvitation.execute(invitation, %ResendClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 token_hash: token_hash("resend")
               })
    end
  end

  describe "execute/2 AcceptClubMemberInvitation" do
    test "marks a pending invitation accepted for the created person and membership" do
      invitation = pending_invitation()
      person_id = Memba.ID.generate(:person)
      membership_id = Memba.ID.generate(:membership)

      assert %ClubMemberInvitationAccepted{
               invitation_id: invitation_id,
               person_id: ^person_id,
               membership_id: ^membership_id
             } =
               ClubInvitation.execute(invitation, %AcceptClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 person_id: person_id,
                 membership_id: membership_id
               })

      assert invitation_id == invitation.invitation_id
    end

    test "rejects missing, accepted, mismatched, or malformed acceptances" do
      assert {:error, :not_found} =
               ClubInvitation.execute(%ClubInvitation{}, %AcceptClubMemberInvitation{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 person_id: Memba.ID.generate(:person),
                 membership_id: Memba.ID.generate(:membership)
               })

      assert {:error, :invitation_id_mismatch} =
               ClubInvitation.execute(pending_invitation(), %AcceptClubMemberInvitation{
                 invitation_id: Memba.ID.generate(:club_invitation),
                 person_id: Memba.ID.generate(:person),
                 membership_id: Memba.ID.generate(:membership)
               })

      invitation = pending_invitation()

      assert {:error, :invalid_person_id} =
               ClubInvitation.execute(invitation, %AcceptClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 person_id: "not-a-person-id",
                 membership_id: Memba.ID.generate(:membership)
               })

      invitation = pending_invitation()

      assert {:error, :invalid_membership_id} =
               ClubInvitation.execute(invitation, %AcceptClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 person_id: Memba.ID.generate(:person),
                 membership_id: "not-a-membership-id"
               })

      invitation = accepted_invitation()

      assert {:error, :already_accepted} =
               ClubInvitation.execute(invitation, %AcceptClubMemberInvitation{
                 invitation_id: invitation.invitation_id,
                 person_id: Memba.ID.generate(:person),
                 membership_id: Memba.ID.generate(:membership)
               })
    end
  end

  test "apply/2 records pending, resent, and accepted state" do
    invitation_id = Memba.ID.generate(:club_invitation)
    club_id = Memba.ID.generate(:club)
    first_hash = token_hash("first")
    second_hash = token_hash("second")
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    invitation =
      ClubInvitation.apply(%ClubInvitation{}, %ClubMemberInvited{
        invitation_id: invitation_id,
        club_id: club_id,
        email: "robin@example.com",
        normalized_email: "robin@example.com",
        token_hash: first_hash
      })

    assert %ClubInvitation{
             invitation_id: ^invitation_id,
             club_id: ^club_id,
             status: :pending,
             resend_count: 0,
             token_hash: ^first_hash
           } = invitation

    invitation =
      ClubInvitation.apply(invitation, %ClubMemberInvitationResent{
        invitation_id: invitation_id,
        token_hash: second_hash
      })

    assert %ClubInvitation{status: :pending, resend_count: 1, token_hash: ^second_hash} =
             invitation

    assert %ClubInvitation{
             status: :accepted,
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } =
             ClubInvitation.apply(invitation, %ClubMemberInvitationAccepted{
               invitation_id: invitation_id,
               person_id: person_id,
               membership_id: membership_id
             })
  end

  defp pending_invitation do
    ClubInvitation.apply(%ClubInvitation{}, %ClubMemberInvited{
      invitation_id: Memba.ID.generate(:club_invitation),
      club_id: Memba.ID.generate(:club),
      email: "robin@example.com",
      normalized_email: "robin@example.com",
      token_hash: token_hash("pending")
    })
  end

  defp accepted_invitation do
    invitation = pending_invitation()

    ClubInvitation.apply(invitation, %ClubMemberInvitationAccepted{
      invitation_id: invitation.invitation_id,
      person_id: Memba.ID.generate(:person),
      membership_id: Memba.ID.generate(:membership)
    })
  end

  defp token_hash(seed), do: InvitationToken.hash_token("token:#{seed}")
end
