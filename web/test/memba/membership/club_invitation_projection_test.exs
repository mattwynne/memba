defmodule Memba.Membership.ClubInvitationProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection

  test "InviteClubMember is projected into the ClubInvitation read model" do
    invitation_id = Memba.ID.generate(:club_invitation)
    club_id = Memba.ID.generate(:club)
    token_hash = token_hash("invite")

    assert is_nil(Repo.get(ClubInvitationProjection, invitation_id))

    assert :ok =
             App.dispatch(
               %InviteClubMember{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: " Robin@Example.COM ",
                 token_hash: token_hash
               },
               consistency: :strong
             )

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
           } = Repo.get(ClubInvitationProjection, invitation_id)
  end

  test "ResendClubMemberInvitation rotates the projected token hash" do
    invitation_id = Memba.ID.generate(:club_invitation)
    club_id = Memba.ID.generate(:club)
    first_hash = token_hash("first")
    second_hash = token_hash("second")

    assert :ok =
             App.dispatch(
               %InviteClubMember{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: "robin@example.com",
                 token_hash: first_hash
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ResendClubMemberInvitation{
                 invitation_id: invitation_id,
                 token_hash: second_hash
               },
               consistency: :strong
             )

    assert %ClubInvitationProjection{
             status: "pending",
             token_hash: ^second_hash,
             resend_count: 1
           } = Repo.get(ClubInvitationProjection, invitation_id)
  end

  test "AcceptClubMemberInvitation marks the projected invitation accepted" do
    invitation_id = Memba.ID.generate(:club_invitation)
    club_id = Memba.ID.generate(:club)
    token_hash = token_hash("invite")
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             App.dispatch(
               %InviteClubMember{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: "robin@example.com",
                 token_hash: token_hash
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %AcceptClubMemberInvitation{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id
               },
               consistency: :strong
             )

    assert %ClubInvitationProjection{
             status: "accepted",
             token_hash: ^token_hash,
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = Repo.get(ClubInvitationProjection, invitation_id)
  end

  defp token_hash(seed), do: InvitationToken.hash_token("token:#{seed}")
end
