defmodule LiveQuery.SourceTest do
  use ExUnit.Case, async: true

  alias LiveQuery.Source

  test "delegates subscription, classification, and opaque matching" do
    owner = self()

    source =
      Source.new!(
        subscribe: fn ->
          send(owner, :subscribed)
          :ok
        end,
        classify: fn {:changed, invalidations} -> {:ok, invalidations} end,
        matches?: fn {:scope, scope}, {:scope, candidate} -> scope == candidate end
      )

    assert Source.subscribe(source) == :ok
    assert_receive :subscribed

    assert Source.classify(source, {:changed, [{:scope, "club-1"}]}) ==
             {:ok, [{:scope, "club-1"}]}

    assert Source.matches?(source, {:scope, "club-1"}, {:scope, "club-1"})
    refute Source.matches?(source, {:scope, "club-1"}, {:scope, "club-2"})
  end

  test "rejects callbacks with the wrong arity" do
    assert_raise ArgumentError,
                 "live query source subscribe must be a zero-argument function",
                 fn ->
                   Source.new!(
                     subscribe: fn _owner -> :ok end,
                     classify: fn _message -> :ignore end,
                     matches?: fn _interest, _invalidation -> false end
                   )
                 end

    assert_raise ArgumentError,
                 "live query source classify must be a one-argument function",
                 fn ->
                   Source.new!(
                     subscribe: fn -> :ok end,
                     classify: fn -> :ignore end,
                     matches?: fn _interest, _invalidation -> false end
                   )
                 end

    assert_raise ArgumentError,
                 "live query source matches? must be a two-argument function",
                 fn ->
                   Source.new!(
                     subscribe: fn -> :ok end,
                     classify: fn _message -> :ignore end,
                     matches?: fn _interest -> false end
                   )
                 end
  end
end
