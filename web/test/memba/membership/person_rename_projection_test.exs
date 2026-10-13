defmodule Memba.Membership.PersonRenameProjectionTest do
  use Memba.EventSourcedCase, async: false
  alias Memba.Membership.{PersonCommands, CommandDispatch}
  alias Memba.Membership.Events.PersonRenamed
  alias Memba.Membership.Projectors.Person, as: PersonProjector

  test "old PersonCreated plus rename replay updates only name and announces committed exact Person change" do
    id = Memba.ID.generate(:person)
    other = Memba.ID.generate(:person)

    for {person_id, email} <- [
          {id, "rename.projection@example.test"},
          {other, "other.projection@example.test"}
        ] do
      {:ok, command} =
        PersonCommands.prepare_create(%{person_id: person_id, name: "Alice Smith", email: email})

      assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    end

    before = Memba.Membership.get_person(id)
    other_before = Memba.Membership.get_person(other)
    emails_before = Memba.Membership.list_person_email_addresses(id)
    Phoenix.PubSub.subscribe(Memba.PubSub, Memba.ReadModelChanges.topic())

    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: id}, %{
        person_id: id,
        name: "Robin Jones",
        expected_name: "Alice Smith"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert_receive {:read_model_changed,
                    %{
                      projector: PersonProjector,
                      source_event: %PersonRenamed{person_id: ^id, name: "Robin Jones"}
                    } = change}

    assert Memba.Membership.get_person(id).name == "Robin Jones"
    assert Memba.Membership.get_person(id).email == before.email
    assert Memba.Membership.get_person(id).person_id == before.person_id
    assert Memba.Membership.get_person(other) == other_before
    assert Memba.Membership.list_person_email_addresses(id) == emails_before

    assert MembaWeb.LiveQuery.MembaReadModelSource.classify({:read_model_changed, change}) ==
             {:ok, [{:person, id}]}

    refute MembaWeb.LiveQuery.MembaReadModelSource.matches?({:person, other}, {:person, id})
    refute MembaWeb.LiveQuery.MembaReadModelSource.matches?({:person_emails, id}, {:person, id})
    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    Memba.ProjectionBarrier.await!([PersonProjector])
    assert Memba.Membership.get_person(id).name == "Robin Jones"
    assert Memba.Membership.get_person(id).email == before.email
    assert Memba.Membership.get_person(other).name == "Alice Smith"
  end
end
