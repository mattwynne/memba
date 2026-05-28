defmodule Memba.Cucumber.MembershipSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Projections.Club, as: ClubProjection

  step "Kootenay Mountaineering Club is a club", context do
    club_name = "Kootenay Mountaineering Club"
    club_id = Ecto.UUID.generate()

    assert :ok =
             App.dispatch(
               %CreateClub{club_id: club_id, name: club_name},
               consistency: :strong
             )

    assert %ClubProjection{club_id: ^club_id, name: ^club_name} = Membership.get_club(club_id)

    clubs =
      context
      |> Map.get(:clubs, %{})
      |> Map.put(club_name, club_id)

    Map.put(context, :clubs, clubs)
  end
end
