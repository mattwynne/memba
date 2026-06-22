defmodule Memba.ClubInboundEmailAddressTest do
  use ExUnit.Case, async: false

  alias Memba.ClubInboundEmailAddress

  test "builds the default whole-club inbound address from a club slug" do
    assert ClubInboundEmailAddress.address(%{slug: "kmc"}) == "everyone@kmc.clubs.memba.io"

    assert ClubInboundEmailAddress.address("nelson-paddling") ==
             "everyone@nelson-paddling.clubs.memba.io"
  end

  test "normalizes lookup-style slug casing and whitespace" do
    assert ClubInboundEmailAddress.address(%{slug: " KMC "}) == "everyone@kmc.clubs.memba.io"
  end

  test "uses the configured inbound email domain" do
    with_club_inbound_email_config([domain: " Example.Clubs.Memba.IO. "], fn ->
      assert ClubInboundEmailAddress.domain() == "example.clubs.memba.io"

      assert ClubInboundEmailAddress.address(%{slug: "kmc"}) ==
               "everyone@kmc.example.clubs.memba.io"
    end)
  end

  test "falls back to the iteration default domain when no domain is configured" do
    with_club_inbound_email_config([], fn ->
      assert ClubInboundEmailAddress.domain() == "clubs.memba.io"
      assert ClubInboundEmailAddress.address(%{slug: "kmc"}) == "everyone@kmc.clubs.memba.io"
    end)
  end

  test "returns nil when the slug is missing or invalid" do
    assert ClubInboundEmailAddress.address(%{}) == nil
    assert ClubInboundEmailAddress.address(nil) == nil
    assert ClubInboundEmailAddress.address("") == nil
    assert ClubInboundEmailAddress.address("not safe") == nil
    assert ClubInboundEmailAddress.address("-kmc") == nil
  end

  defp with_club_inbound_email_config(config, fun) do
    original = Application.get_env(:memba, :club_inbound_email)

    try do
      Application.put_env(:memba, :club_inbound_email, config)
      fun.()
    after
      restore_club_inbound_email_config(original)
    end
  end

  defp restore_club_inbound_email_config(nil),
    do: Application.delete_env(:memba, :club_inbound_email)

  defp restore_club_inbound_email_config(config),
    do: Application.put_env(:memba, :club_inbound_email, config)
end
