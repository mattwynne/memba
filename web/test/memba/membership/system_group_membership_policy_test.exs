defmodule Memba.Membership.SystemGroupMembershipPolicyTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Policies.SystemGroupMembership

  test "is a stateless strongly consistent Commanded event handler starting from current events" do
    assert %{
             id: {SystemGroupMembership, opts},
             restart: :permanent,
             start: {SystemGroupMembership, :start_link, [opts]},
             type: :worker
           } = SystemGroupMembership.child_spec([])

    assert Keyword.fetch!(opts, :application) == Memba.Membership.App
    assert Keyword.fetch!(opts, :name) == "Memba.Membership.Policies.SystemGroupMembership"
    assert Keyword.fetch!(opts, :consistency) == :strong
    assert Keyword.fetch!(opts, :start_from) == :current
    refute Keyword.has_key?(opts, :state)
  end
end
