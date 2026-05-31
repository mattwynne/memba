defmodule Memba.Membership.NoCrudSpikeTest do
  use ExUnit.Case, async: true

  @web_root Path.expand("../../..", __DIR__)

  test "public Membership context exposes approved command APIs instead of CRUD helpers" do
    source = read_source!("lib/memba/membership.ex")

    assert source =~ "def create_club("
    assert source =~ "def create_person("
    assert source =~ "def add_member("
    assert source =~ "def get_club("
    assert source =~ "def list_clubs("
    assert source =~ "def list_people("
    assert source =~ "def list_active_members_of_club("
    assert source =~ "def list_active_clubs_for_member_email("

    list_functions =
      ~r/\bdef\s+(list_[a-zA-Z0-9_]+)\b/
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    assert list_functions == [
             "list_clubs",
             "list_people",
             "list_active_members_of_club",
             "list_active_clubs_for_member_email"
           ]

    create_functions =
      ~r/\bdef\s+(create_[a-zA-Z0-9_]+)\b/
      |> Regex.scan(source, capture: :all_but_first)
      |> List.flatten()

    assert create_functions == ["create_club", "create_person"]
    refute source =~ ~r/\bdef\s+(update|delete|change)_[a-zA-Z0-9_]+\b/
    refute source =~ ~r/\bRepo\.(insert|update|delete)\b/
  end

  test "club aggregate is not the former Ecto schema and changeset module" do
    source = read_source!("lib/memba/membership/club.ex")

    assert source =~ "@behaviour Aggregate"
    assert source =~ "def execute("
    assert source =~ "def apply("
    refute source =~ "use Ecto.Schema"
    refute source =~ ~r/\bdef\s+changeset\b/
  end

  test "Membership migrations only create projection storage for this slice" do
    migration_sources =
      "priv/repo/migrations/*.exs"
      |> path()
      |> Path.wildcard()
      |> Enum.map(&File.read!/1)

    assert Enum.any?(migration_sources, &String.contains?(&1, "create table(:membership_clubs"))

    refute Enum.any?(migration_sources, fn source ->
             source =~ ~r/create\s+table\(\s*:(clubs|people|persons|members|memberships)\b/
           end)
  end

  test "legacy generated Membership CRUD context test is absent" do
    refute "test/memba/membership_test.exs"
           |> path()
           |> File.exists?()
  end

  defp read_source!(relative_path) do
    relative_path
    |> path()
    |> File.read!()
  end

  defp path(relative_path), do: Path.join(@web_root, relative_path)
end
