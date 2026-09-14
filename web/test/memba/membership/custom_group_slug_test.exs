defmodule Memba.Membership.CustomGroupSlugTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.CustomGroupSlug
  alias Memba.Membership.Slug

  test "allocates the first available numeric suffix" do
    occupied_slugs = MapSet.new(["board", "board-2", "board-4"])

    assert CustomGroupSlug.allocate("Board", occupied_slugs) == "board-3"
  end

  test "shortens a maximum-length stem to keep a suffix address-safe" do
    stem = String.duplicate("a", Slug.max_length())
    occupied_slugs = MapSet.new([stem])

    allocated_slug = CustomGroupSlug.allocate(stem, occupied_slugs)

    assert allocated_slug == String.duplicate("a", Slug.max_length() - 2) <> "-2"
    assert String.length(allocated_slug) == Slug.max_length()
    assert Slug.valid?(allocated_slug)
  end

  test "shortens the stem again when the first available suffix gains a digit" do
    stem = String.duplicate("a", Slug.max_length())

    occupied_slugs =
      1..9
      |> Enum.map(fn
        1 -> stem
        suffix -> String.slice(stem, 0, Slug.max_length() - 2) <> "-#{suffix}"
      end)
      |> MapSet.new()

    allocated_slug = CustomGroupSlug.allocate(stem, occupied_slugs)

    assert allocated_slug == String.duplicate("a", Slug.max_length() - 3) <> "-10"
    assert String.length(allocated_slug) == Slug.max_length()
    assert Slug.valid?(allocated_slug)
  end

  test "uses and suffixes a fallback when the display name has no ASCII stem" do
    assert CustomGroupSlug.allocate("董事会", MapSet.new()) == "group"
    assert CustomGroupSlug.allocate("Совет", MapSet.new(["group"])) == "group-2"
  end
end
