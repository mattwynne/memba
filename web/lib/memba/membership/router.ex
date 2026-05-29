defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson

  identify(Club, by: :club_id)
  identify(Person, by: :person_id)

  dispatch(CreateClub, to: Club)
  dispatch(CreatePerson, to: Person)
end
