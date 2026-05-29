defmodule Memba.Membership.Projectors.Person do
  @moduledoc """
  Projects person events into the Membership person read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Person",
    consistency: :strong

  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Projections.Person, as: PersonProjection

  project(%PersonCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :membership_person, %PersonProjection{
      person_id: event.person_id,
      name: event.name,
      email: event.email
    })
  end)
end
