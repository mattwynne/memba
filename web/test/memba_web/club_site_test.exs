defmodule MembaWeb.ClubSiteTest do
  use ExUnit.Case, async: false

  alias MembaWeb.ClubSite

  test "builds local club URLs from the configured test base domain" do
    club = %{slug: "kmc"}

    assert ClubSite.url(club) == "http://kmc.lvh.me:4002/"
    assert ClubSite.url(club, "/messages/new") == "http://kmc.lvh.me:4002/messages/new"
  end

  test "extracts the left-most slug from configured club hosts" do
    assert ClubSite.slug_from_host("kmc.lvh.me") == {:ok, "kmc"}
    assert ClubSite.slug_from_host("KMC.LVH.ME.") == {:ok, "kmc"}
    assert ClubSite.slug_from_host("preview.kmc.lvh.me") == {:ok, "preview"}
  end

  test "ignores non-club hosts" do
    assert ClubSite.slug_from_host("lvh.me") == :error
    assert ClubSite.slug_from_host("memba.io") == :error
    assert ClubSite.slug_from_host(nil) == :error
  end

  test "production-like configuration uses clubs.memba.io without a port" do
    original = Application.get_env(:memba, :club_site)

    try do
      Application.put_env(:memba, :club_site,
        base_domain: "clubs.memba.io",
        scheme: "https",
        port: 443
      )

      assert ClubSite.url(%{slug: "kmc"}) == "https://kmc.clubs.memba.io/"
      assert ClubSite.slug_from_host("kmc.clubs.memba.io") == {:ok, "kmc"}
    after
      Application.put_env(:memba, :club_site, original)
    end
  end
end
