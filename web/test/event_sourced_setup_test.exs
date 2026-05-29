defmodule Memba.EventSourcedSetupTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Memba.Repo

  test "mix aliases create and reset EventStore with projection migrations" do
    aliases = Keyword.fetch!(Memba.MixProject.project(), :aliases)

    assert aliases[:setup] == ["deps.get", "ecto.setup", "assets.setup", "assets.build"]

    assert aliases[:"ecto.setup"] == [
             "ecto.create",
             "event_store.setup",
             "ecto.migrate",
             "run priv/repo/seeds.exs"
           ]

    assert aliases[:"ecto.reset"] == ["ecto.drop", "ecto.setup"]
    assert aliases[:"event_store.setup"] == ["event_store.create", "event_store.init"]
    assert aliases[:"event_store.reset"] == ["event_store.drop", "event_store.setup"]

    assert aliases[:test] == [
             "ecto.drop --quiet",
             "ecto.create --quiet",
             "event_store.create --quiet",
             "ecto.migrate --quiet",
             "event_store.init --quiet",
             "test"
           ]
  end

  test "projection tables are migrated in the application schema" do
    assert [[true]] = query!("SELECT to_regclass('public.projection_versions') IS NOT NULL").rows
    assert [[true]] = query!("SELECT to_regclass('public.membership_clubs') IS NOT NULL").rows
    assert [[true]] = query!("SELECT to_regclass('public.membership_people') IS NOT NULL").rows
  end

  test "event-sourced test helper resets EventStore and projection rows" do
    Memba.EventSourcedCase.reset_event_sourced_storage!()

    if is_nil(Process.whereis(Memba.EventStore)) do
      start_supervised!(Memba.EventStore)
    end

    event_data = %EventStore.EventData{
      event_type: "Elixir.EventStore.EventData",
      data: %{"data" => %{"value" => "created"}, "event_type" => "reset_test_event"},
      metadata: %{}
    }

    assert :ok =
             Memba.EventStore.append_to_stream("reset-test-#{Ecto.UUID.generate()}", 0, [
               event_data
             ])

    query!("""
    INSERT INTO projection_versions (projection_name, last_seen_event_number, inserted_at, updated_at)
    VALUES ('setup-test-projector', 1, now(), now())
    """)

    club_id = Ecto.UUID.generate()

    query!("""
    INSERT INTO membership_clubs (club_id, name, inserted_at, updated_at)
    VALUES ('#{club_id}', 'Kootenay Mountaineering Club', now(), now())
    """)

    person_id = Ecto.UUID.generate()

    query!("""
    INSERT INTO membership_people (person_id, name, email, inserted_at, updated_at)
    VALUES ('#{person_id}', 'Alice', 'alice@example.com', now(), now())
    """)

    assert [[1]] = query!(~S|SELECT count(*) FROM "event_store"."events"|).rows
    assert [[1]] = query!("SELECT count(*) FROM projection_versions").rows
    assert [[1]] = query!("SELECT count(*) FROM membership_clubs").rows
    assert [[1]] = query!("SELECT count(*) FROM membership_people").rows

    Memba.EventSourcedCase.reset_event_sourced_storage!()

    assert [[0]] = query!(~S|SELECT count(*) FROM "event_store"."events"|).rows
    assert [[0]] = query!("SELECT count(*) FROM projection_versions").rows
    assert [[0]] = query!("SELECT count(*) FROM membership_clubs").rows
    assert [[0]] = query!("SELECT count(*) FROM membership_people").rows
    assert [["$all"]] = query!(~S|SELECT stream_uuid FROM "event_store"."streams"|).rows
  end

  defp query!(sql) do
    Sandbox.unboxed_run(Repo, fn -> Repo.query!(sql, []) end)
  end
end
