defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.Membership
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.UpdateClub

  identify(Club, by: :club_id)
  identify(Membership, by: :membership_id)
  identify(Person, by: :person_id)

  dispatch(AddMember, to: Membership)
  dispatch(AssignMemberRole, to: Club)
  dispatch(CreateClub, to: Club)
  dispatch(CreatePerson, to: Person)
  dispatch(DefineClubRole, to: Club)
  dispatch(GrantClubRolePermission, to: Club)
  dispatch(RemoveMember, to: Membership)
  dispatch(RemoveMemberRole, to: Club)
  dispatch(ReplacePersonEmailAddresses, to: Person)
  dispatch(UpdateClub, to: Club)
end
