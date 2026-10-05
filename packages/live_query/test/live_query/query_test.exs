defmodule LiveQuery.QueryTest do
  use ExUnit.Case, async: true

  alias LiveQuery.Query

  test "constructs a stable one-assign query and delegates loading" do
    loader = fn inputs -> {:ok, %{inputs: inputs}, [{:scope, inputs}]} end
    query = Query.new!(id: {:members, 1}, assign: :members, load: loader)

    assert query.id == {:members, 1}
    assert query.assign == :members

    assert Query.load(query, "club-1") ==
             {:ok, %{inputs: "club-1"}, [{:scope, "club-1"}]}
  end

  test "rejects a non-atom assign" do
    assert_raise ArgumentError, "live query assign must be an atom, got: \"members\"", fn ->
      Query.new!(id: :members, assign: "members", load: fn _inputs -> {:ok, nil, []} end)
    end
  end

  test "rejects a loader with the wrong arity" do
    assert_raise ArgumentError, "live query load must be a one-argument function", fn ->
      Query.new!(id: :members, assign: :members, load: fn -> {:ok, nil, []} end)
    end
  end
end
