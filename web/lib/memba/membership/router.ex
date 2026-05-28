defmodule Memba.Membership.Router do
  @moduledoc """
  Command router for Membership commands.
  """

  use Commanded.Commands.Router

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub

  identify(Club, by: :club_id)

  dispatch(CreateClub, to: Club)
end
