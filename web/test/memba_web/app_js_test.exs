defmodule MembaWeb.AppJsTest do
  use ExUnit.Case, async: true

  @app_js_path Path.expand("../../assets/js/app.js", __DIR__)

  test "LiveSocket delays disconnected presentation commands by exactly 1500ms" do
    source = File.read!(@app_js_path)

    assert [options] =
             Regex.run(
               ~r/new LiveSocket\("\/live", Socket, \{(?<options>.*?)^\}\)/ms,
               source,
               capture: ["options"]
             ),
           "Expected app.js to construct LiveSocket with an inline options object"

    configured_timeouts =
      Regex.scan(
        ~r/^\s*disconnectedTimeout:\s*(\d+),?\s*$/m,
        options,
        capture: :all_but_first
      )
      |> List.flatten()

    assert configured_timeouts == ["1500"],
           "Expected the LiveSocket options to set disconnectedTimeout exactly once to 1500, " <>
             "got: #{inspect(configured_timeouts)}"
  end
end
