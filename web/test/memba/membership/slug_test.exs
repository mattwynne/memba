defmodule Memba.Membership.SlugTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Slug

  describe "default_from_name/1" do
    test "generates lowercase kebab-case defaults from club names" do
      assert Slug.default_from_name("Kootenay Mountaineering Club") ==
               "kootenay-mountaineering-club"

      assert Slug.default_from_name("  KMC Alpine & Ski Club!  ") == "kmc-alpine-ski-club"
    end

    test "removes leading and trailing separators from generated defaults" do
      assert Slug.default_from_name("!!! KMC Club ???") == "kmc-club"
    end

    test "limits generated defaults to the maximum slug length without trailing hyphens" do
      assert Slug.default_from_name("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa club") ==
               "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

      generated = Slug.default_from_name("Kootenay Mountaineering Club Alpine Section")

      assert String.length(generated) <= Slug.max_length()
      refute String.ends_with?(generated, "-")
    end

    test "returns an empty default when a name cannot produce slug characters" do
      assert Slug.default_from_name(" !!! ") == ""
      assert Slug.default_from_name(nil) == ""
    end
  end

  describe "validate/1" do
    test "accepts address-safe staff-entered slugs" do
      assert Slug.validate("kmc") == {:ok, "kmc"}

      assert Slug.validate("kootenay-mountaineering-club") ==
               {:ok, "kootenay-mountaineering-club"}

      assert Slug.validate("club-123") == {:ok, "club-123"}
      assert Slug.validate("club--section") == {:ok, "club--section"}

      assert Slug.validate(String.duplicate("a", Slug.max_length())) ==
               {:ok, String.duplicate("a", Slug.max_length())}
    end

    test "rejects blank and non-string slugs" do
      assert Slug.validate("") == {:error, :blank}
      assert Slug.validate(nil) == {:error, :invalid_format}
    end

    test "rejects values that are not already address-safe" do
      assert Slug.validate("KMC") == {:error, :invalid_format}
      assert Slug.validate(" kmc ") == {:error, :invalid_format}
      assert Slug.validate("kmc club") == {:error, :invalid_format}
      assert Slug.validate("kmc_club") == {:error, :invalid_format}
      assert Slug.validate("kmc.club") == {:error, :invalid_format}
      assert Slug.validate("kmc!") == {:error, :invalid_format}
      assert Slug.validate("-kmc") == {:error, :invalid_format}
      assert Slug.validate("kmc-") == {:error, :invalid_format}
    end

    test "rejects slugs longer than the maximum length" do
      assert Slug.validate(String.duplicate("a", Slug.max_length() + 1)) == {:error, :too_long}
    end
  end

  describe "valid?/1" do
    test "returns a boolean validity result" do
      assert Slug.valid?("kmc")
      refute Slug.valid?("KMC")
    end
  end
end
