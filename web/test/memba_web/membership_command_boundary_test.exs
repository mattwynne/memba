defmodule MembaWeb.MembershipCommandBoundaryTest do
  use ExUnit.Case, async: true

  @web_source_root Path.expand("../../lib/memba_web", __DIR__)

  @internal_membership_references [
    "Memba.Membership.Commands.AddGroupMember",
    "Memba.Membership.Commands.CreateGroup",
    "Memba.Membership.Commands.RemoveGroupMember"
  ]

  test "web delivery does not bypass the public Membership command boundary" do
    @web_source_root
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      source = File.read!(path)
      relative_path = Path.relative_to(path, @web_source_root)

      Enum.each(@internal_membership_references, fn internal_reference ->
        refute source =~ internal_reference,
               "#{relative_path} must use the public Memba.Membership API, " <>
                 "not #{internal_reference}"
      end)
    end)
  end
end
