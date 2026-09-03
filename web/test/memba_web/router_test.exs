defmodule MembaWeb.RouterTest do
  use MembaWeb.ConnCase, async: true

  @old_harness_paths [
    "/clubs",
    "/clubs/club-123",
    "/deliveries"
  ]

  @custom_group_paths [
    "/groups",
    "/groups/new",
    "/groups/group-123",
    "/groups/group-123/members",
    "/admin/groups",
    "/admin/clubs/club-123/groups",
    "/admin/clubs/club-123/groups/new",
    "/admin/clubs/club-123/groups/group-123"
  ]

  describe "Memba staff LiveView routes" do
    test "routes /admin/clubs through the staff browser pipeline to the clubs index LiveView" do
      assert_live_route("/admin/clubs", "/admin/clubs", MembaWeb.Admin.ClubsLive.Index, %{})
    end

    test "routes /admin/requests through the staff browser pipeline to the requests index LiveView" do
      assert_live_route(
        "/admin/requests",
        "/admin/requests",
        MembaWeb.Admin.RequestsLive.Index,
        %{},
        :index
      )
    end

    test "routes /admin/requests/:request_id through the staff browser pipeline to the requests conversion LiveView" do
      assert_live_route(
        "/admin/requests/req_123",
        "/admin/requests/:request_id",
        MembaWeb.Admin.RequestsLive.Index,
        %{"request_id" => "req_123"},
        :convert
      )
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

    test "routes Postmark inbound webhook requests through the json api pipeline" do
      assert %{
               path_params: %{},
               pipe_through: [:api],
               plug: MembaWeb.PostmarkInboundWebhookController,
               plug_opts: :create,
               route: "/webhooks/postmark/inbound"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "POST",
                 "/webhooks/postmark/inbound",
                 "localhost"
               )
    end
  end

  describe "member message routes" do
    test "does not route the legacy inline club-home send endpoint" do
      assert :error = Phoenix.Router.route_info(MembaWeb.Router, "POST", "/", "localhost")
    end

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

    test "routes /messages/:message_id/delivery through the required club member pipeline to the member message delivery LiveView" do
      assert %{
               path_params: %{"message_id" => "message-123"},
               pipe_through: [:browser, :club_member_required],
               phoenix_live_view:
                 {MembaWeb.MemberMessageDeliveryLive.Show, nil, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: nil,
               route: "/messages/:message_id/delivery"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "GET",
                 "/messages/message-123/delivery",
                 "localhost"
               )
    end
  end

  describe "member invitation routes" do
    test "routes /members/invitations/new through the required club member pipeline to the invitation LiveView" do
      assert %{
               path_params: %{},
               pipe_through: [:browser, :club_member_required],
               phoenix_live_view: {MembaWeb.MemberInvitationLive.New, :new, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: :new,
               route: "/members/invitations/new"
             } =
               Phoenix.Router.route_info(
                 MembaWeb.Router,
                 "GET",
                 "/members/invitations/new",
                 "localhost"
               )
    end
  end

  describe "my settings routes" do
    test "routes /my/settings through the required club member pipeline to the settings LiveView" do
      assert_my_settings_live_route("/my/settings", "/my/settings", %{}, :profile)
    end

    test "routes URL-addressable settings tabs through the settings LiveView" do
      assert_my_settings_live_route("/my/settings/profile", "/my/settings/profile", %{}, :profile)
      assert_my_settings_live_route("/my/settings/clubs", "/my/settings/clubs", %{}, :clubs)
      assert_my_settings_live_route("/my/settings/emails", "/my/settings/emails", %{}, :emails)
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

  describe "custom group routes" do
    test "custom group UI/API paths are not routed in this slice" do
      for method <- ~w(GET POST PATCH DELETE),
          path <- @custom_group_paths do
        assert :error = Phoenix.Router.route_info(MembaWeb.Router, method, path, "localhost")
      end
    end
  end

  defp assert_live_route(path, route_pattern, live_view, path_params, live_action \\ nil) do
    assert %{
             pipe_through: [:staff_browser],
             phoenix_live_view: {^live_view, ^live_action, _opts, _live_session},
             plug: Phoenix.LiveView.Plug,
             plug_opts: ^live_action,
             path_params: ^path_params,
             route: ^route_pattern
           } = Phoenix.Router.route_info(MembaWeb.Router, "GET", path, "localhost")
  end

  defp assert_my_settings_live_route(path, route_pattern, path_params, live_action) do
    assert %{
             path_params: ^path_params,
             pipe_through: [:browser, :club_member_required],
             phoenix_live_view: {MembaWeb.MySettingsLive, ^live_action, _opts, _live_session},
             plug: Phoenix.LiveView.Plug,
             plug_opts: ^live_action,
             route: ^route_pattern
           } =
             Phoenix.Router.route_info(
               MembaWeb.Router,
               "GET",
               path,
               "localhost"
             )
  end
end
