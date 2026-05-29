defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.Membership
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson

  identify(Club, by: :club_id)
  identify(Membership, by: :membership_id)
  identify(Person, by: :person_id)

  dispatch(AddMember, to: Membership)
  dispatch(CreateClub, to: Club)
  dispatch(CreatePerson, to: Person)
end
