defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.ClubInvitation
  alias Memba.Membership.Membership
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Commands.VerifyPersonEmailAddress

  identify(Club, by: :club_id)
  identify(ClubInvitation, by: :invitation_id)
  identify(Membership, by: :membership_id)
  identify(Person, by: :person_id)

  dispatch(AcceptClubMemberInvitation, to: ClubInvitation)
  dispatch(AddMember, to: Membership)
  dispatch(AddPersonEmailAddress, to: Person)
  dispatch(AssignMemberRole, to: Club)
  dispatch(CreateClub, to: Club)
  dispatch(CreatePerson, to: Person)
  dispatch(DefineClubRole, to: Club)
  dispatch(GrantClubRolePermission, to: Club)
  dispatch(InviteClubMember, to: ClubInvitation)
  dispatch(MakePersonEmailAddressPrimary, to: Person)
  dispatch(RemoveMember, to: Membership)
  dispatch(RemoveMemberRole, to: Club)
  dispatch(RemovePersonEmailAddress, to: Person)
  dispatch(ReplacePersonEmailAddresses, to: Person)
  dispatch(ResendClubMemberInvitation, to: ClubInvitation)
  dispatch(UpdateClub, to: Club)
  dispatch(VerifyPersonEmailAddress, to: Person)
end
