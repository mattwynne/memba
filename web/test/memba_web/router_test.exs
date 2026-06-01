defmodule MembaWeb.RouterTest do
  use MembaWeb.ConnCase, async: true

  @old_harness_paths [
    "/clubs",
    "/clubs/club-123",
    "/deliveries"
  ]

  describe "staff admin LiveView routes" do
    test "routes /admin/clubs through the staff browser pipeline to the clubs index LiveView" do
      assert_live_route("/admin/clubs", "/admin/clubs", MembaWeb.Admin.ClubsLive.Index, %{})
    end

    test "routes /admin/clubs/:club_id through the staff browser pipeline to the club show LiveView" do
      assert_live_route(
        "/admin/clubs/club-123",
        "/admin/clubs/:club_id",
        MembaWeb.Admin.ClubsLive.Show,
        %{
          "club_id" => "club-123"
        }
      )
    end

    test "routes /admin/deliveries through the staff browser pipeline to the deliveries index LiveView" do
      assert_live_route(
        "/admin/deliveries",
        "/admin/deliveries",
        MembaWeb.Admin.DeliveriesLive.Index,
        %{}
      )
    end

    test "routes /admin/messages/:message_id through the staff browser pipeline to the message show LiveView" do
      assert_live_route(
        "/admin/messages/message-123",
        "/admin/messages/:message_id",
        MembaWeb.Admin.MessagesLive.Show,
        %{"message_id" => "message-123"}
      )
    end
  end

  describe "webhook routes" do
    test "routes Postmark webhook requests through the json api pipeline" do
      assert %{
               path_params: %{},
               pipe_through: [:api],
               plug: MembaWeb.PostmarkWebhookController,
               plug_opts: :create,
               route: "/webhooks/postmark"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "POST",
                 "/webhooks/postmark",
                 "localhost"
               )
    end
  end

  describe "member message routes" do
    test "routes /messages/new through the required club member pipeline to the compose LiveView" do
      assert %{
               path_params: %{},
               pipe_through: [:browser, :club_member_required],
               phoenix_live_view: {MembaWeb.MemberMessageLive.New, :new, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: :new,
               route: "/messages/new"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "GET",
                 "/messages/new",
                 "localhost"
               )
    end

    test "routes /messages/:message_id through the required club member pipeline to the member message LiveView" do
      assert %{
               path_params: %{"message_id" => "message-123"},
               pipe_through: [:browser, :club_member_required],
               phoenix_live_view: {MembaWeb.MemberMessageLive.Show, :show, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: :show,
               route: "/messages/:message_id"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "GET",
                 "/messages/message-123",
                 "localhost"
               )
    end
  end

  describe "removed public harness routes" do
    test "old harness paths return the normal 404 response without redirects", %{conn: conn} do
      Enum.each(@old_harness_paths, fn path ->
        conn =
          conn
          |> recycle()
          |> get(path)

        assert response(conn, 404) == "Not Found"
        assert get_resp_header(conn, "location") == []
      end)
    end
  end

  defp assert_live_route(path, route_pattern, live_view, path_params) do
    assert %{
             pipe_through: [:staff_browser],
             phoenix_live_view: {^live_view, nil, _opts, _live_session},
             plug: Phoenix.LiveView.Plug,
             plug_opts: nil,
             path_params: ^path_params,
             route: ^route_pattern
           } = Phoenix.Router.route_info(MembaWeb.Router, "GET", path, "localhost")
  end
end
