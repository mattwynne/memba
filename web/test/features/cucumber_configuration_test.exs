defmodule Memba.CucumberConfigurationTest do
  use ExUnit.Case, async: true

  test "Cucumber discovers shared feature files from acceptance-tests" do
    assert configured_feature_paths() == expected_shared_feature_paths()
  end

  test "domain Cucumber configuration excludes scenarios not ready or not intended for domain" do
    assert Application.fetch_env!(:cucumber, :tags) ==
             "not @not-domain and not @todo-domain"
  end

  defp configured_feature_paths do
    :cucumber
    |> Application.fetch_env!(:features)
    |> List.wrap()
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expected_shared_feature_paths do
    __DIR__
    |> Path.join("../../../acceptance-tests/features/**/*.feature")
    |> Path.expand()
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> Enum.sort()
  end
end
