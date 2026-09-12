defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.

  Membership activation and removal share the Club aggregate boundary with
  club roles and their invariants. There is no membership-ID aggregate route.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.ClubInvitation
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.AssignGroupEmailSlug
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Commands.VerifyPersonEmailAddress

  identify(Club, by: :club_id)
  identify(ClubInvitation, by: :invitation_id)
  identify(Person, by: :person_id)

  dispatch(AcceptClubMemberInvitation, to: ClubInvitation)
  dispatch(AddGroupMember, to: Club)
  dispatch(AddClubMember, to: Club)
  dispatch(AddPersonEmailAddress, to: Person)
  dispatch(AssignGroupEmailSlug, to: Club)
  dispatch(AssignClubRoleToMember, to: Club)
  dispatch(CreateClub, to: Club)
  dispatch(CreateGroup, to: Club)
  dispatch(CreatePerson, to: Person)
  dispatch(DefineClubRole, to: Club)
  dispatch(GrantClubRolePermission, to: Club)
  dispatch(InviteClubMember, to: ClubInvitation)
  dispatch(MakePersonEmailAddressPrimary, to: Person)
  dispatch(RemoveGroupMember, to: Club)
  dispatch(RemoveClubMember, to: Club)
  dispatch(RemoveClubRoleFromMember, to: Club)
  dispatch(RemovePersonEmailAddress, to: Person)
  dispatch(ReplacePersonEmailAddresses, to: Person)
  dispatch(ResendClubMemberInvitation, to: ClubInvitation)
  dispatch(UpdateClub, to: Club)
  dispatch(VerifyPersonEmailAddress, to: Person)
end
