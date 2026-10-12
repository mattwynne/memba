defmodule Memba.Messaging.NoCrudSpikeTest do
  use ExUnit.Case, async: true

  @web_root Path.expand("../../..", __DIR__)

  test "message aggregate is not a generated Ecto schema and changeset module" do
    source = read_source!("lib/memba/messaging/message.ex")

    assert source =~ "@behaviour Aggregate"
    assert source =~ "def execute("
    assert source =~ "def apply("
    refute source =~ "use Ecto.Schema"
    refute source =~ ~r/\bdef\s+changeset\b/
  end

  test "Messaging migrations only create projection storage for this slice" do
    migration_sources =
      "priv/repo/migrations/*.exs"
      |> path()
      |> Path.wildcard()
      |> Enum.map(&File.read!/1)

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_messages")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_email_deliveries")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_member_email_deliveries")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_memba_staff_email_deliveries")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_conversation_follows")
           )

    refute Enum.any?(migration_sources, fn source ->
             source =~
               ~r/create\s+table\(\s*:(messages|message_recipients|message_deliveries|recipient_deliveries|deliveries)\b/
           end)
  end

  test "legacy generated Messaging CRUD web and fixture files are absent" do
    refute "test/memba/messaging_test.exs" |> path() |> File.exists?()
    refute "test/support/fixtures/messaging_fixtures.ex" |> path() |> File.exists?()
    refute "lib/memba_web/controllers/message_controller.ex" |> path() |> File.exists?()
    refute "test/memba_web/controllers/message_controller_test.exs" |> path() |> File.exists?()
    refute "lib/memba_web/controllers/message_html.ex" |> path() |> File.exists?()
    refute "lib/memba_web/controllers/message_json.ex" |> path() |> File.exists?()
    refute "lib/memba_web/live/message_live/index.ex" |> path() |> File.exists?()
    refute "lib/memba_web/live/message_live/show.ex" |> path() |> File.exists?()
    refute "lib/memba_web/live/message_live/form_component.ex" |> path() |> File.exists?()
  end

  defp read_source!(relative_path) do
    relative_path
    |> path()
    |> File.read!()
  end

  defp path(relative_path), do: Path.join(@web_root, relative_path)
end
