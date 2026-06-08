defmodule Memba.Membership.ClubInvitationDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.ClubInvitation
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.InvitationToken

  test "Membership app dispatch routes invitation commands to the ClubInvitation aggregate" do
    invitation_id = Memba.ID.generate(:club_invitation)
    club_id = Memba.ID.generate(:club)
    first_hash = token_hash("first")
    second_hash = token_hash("second")
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^invitation_id,
              aggregate_version: 1,
              events: [
                %ClubMemberInvited{
                  invitation_id: ^invitation_id,
                  club_id: ^club_id,
                  normalized_email: "robin@example.com",
                  token_hash: ^first_hash
                }
              ],
              aggregate_state: %ClubInvitation{
                invitation_id: ^invitation_id,
                club_id: ^club_id,
                normalized_email: "robin@example.com",
                token_hash: ^first_hash,
                status: :pending
              }
            }} =
             App.dispatch(
               %InviteClubMember{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: "robin@example.com",
                 token_hash: first_hash
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_version: 2,
              events: [
                %ClubMemberInvitationResent{
                  invitation_id: ^invitation_id,
                  token_hash: ^second_hash
                }
              ]
            }} =
             App.dispatch(
               %ResendClubMemberInvitation{
                 invitation_id: invitation_id,
                 token_hash: second_hash
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_version: 3,
              events: [
                %ClubMemberInvitationAccepted{
                  invitation_id: ^invitation_id,
                  person_id: ^person_id,
                  membership_id: ^membership_id
                }
              ],
              aggregate_state: %ClubInvitation{status: :accepted}
            }} =
             App.dispatch(
               %AcceptClubMemberInvitation{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubInvitation{
             invitation_id: ^invitation_id,
             club_id: ^club_id,
             status: :accepted,
             token_hash: ^second_hash,
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = App.aggregate_state(ClubInvitation, invitation_id)
  end

  defp token_hash(seed), do: InvitationToken.hash_token("token:#{seed}")
end
