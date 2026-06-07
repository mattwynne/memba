defmodule Memba.CucumberConfigurationTest do
  use ExUnit.Case, async: true

  @deliverability_feature_names [
    "member_message_deliverability.feature",
    "memba_staff_email_deliverability.feature"
  ]

  test "Cucumber discovers shared feature files from acceptance-tests" do
    assert configured_feature_paths() == expected_shared_feature_paths()
  end

  test "domain Cucumber configuration excludes scenarios not ready or not intended for domain" do
    assert Application.fetch_env!(:cucumber, :tags) ==
             "not @not-domain and not @todo-domain and not @todo and not @wip"
  end

  test "shared deliverability features do not describe opened receipts" do
    configured_feature_paths()
    |> Enum.filter(&(Path.basename(&1) in @deliverability_feature_names))
    |> Enum.each(fn deliverability_feature_file ->
      feature_text = File.read!(deliverability_feature_file)

      refute feature_text =~ ~r/\b(opened|opens|open tracking|track_opens)\b/i
    end)
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
