defmodule Memba.Messaging.NoCrudSpikeTest do
  use ExUnit.Case, async: true

  @web_root Path.expand("../../..", __DIR__)

  test "public Messaging context exposes command and query APIs instead of CRUD helpers" do
    source = read_source!("lib/memba/messaging.ex")

    assert source =~ "def send_club_message("
    assert source =~ "def get_message("
    assert source =~ "def get_recipient_delivery("
    assert source =~ "def get_member_receipt("
    assert source =~ "def get_operator_deliverability("
    assert source =~ "def list_recipient_deliveries("
    assert source =~ "def list_member_receipts("
    assert source =~ "def list_operator_deliverabilities("

    list_functions =
      ~r/\bdef\s+(list_[a-zA-Z0-9_]+)\b/
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    assert list_functions == [
             "list_recipient_deliveries",
             "list_member_receipts",
             "list_operator_deliverabilities"
           ]

    refute source =~ ~r/\bdef\s+(create|update|delete|change)_[a-zA-Z0-9_]+\b/
    refute source =~ ~r/\bRepo\.(insert|update|delete)\b/
  end

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
             &String.contains?(&1, "create table(:messaging_recipient_deliveries")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_member_receipts")
           )

    assert Enum.any?(
             migration_sources,
             &String.contains?(&1, "create table(:messaging_operator_deliverabilities")
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
