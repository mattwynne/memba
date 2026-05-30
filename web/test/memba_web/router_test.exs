defmodule MembaWeb.RouterTest do
  use ExUnit.Case, async: true

  describe "browser LiveView routes" do
    test "routes /clubs through the browser pipeline to the clubs index LiveView" do
      assert_live_route("/clubs", "/clubs", MembaWeb.ClubsLive.Index, %{})
    end

    test "routes /clubs/:club_id through the browser pipeline to the club show LiveView" do
      assert_live_route("/clubs/club-123", "/clubs/:club_id", MembaWeb.ClubsLive.Show, %{
        "club_id" => "club-123"
      })
    end

    test "routes /messages/:message_id through the browser pipeline to the message show LiveView" do
      assert_live_route(
        "/messages/message-123",
        "/messages/:message_id",
        MembaWeb.MessagesLive.Show,
        %{"message_id" => "message-123"}
      )
    end
  end

  defp assert_live_route(path, route_pattern, live_view, path_params) do
    assert %{
             pipe_through: [:browser],
             phoenix_live_view: {^live_view, nil, _opts, _live_session},
             plug: Phoenix.LiveView.Plug,
             plug_opts: nil,
             path_params: ^path_params,
             route: ^route_pattern
           } = Phoenix.Router.route_info(MembaWeb.Router, "GET", path, "localhost")
  end
end
