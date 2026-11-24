defmodule MembaWeb.Router do
  use MembaWeb, :router

  import MembaWeb.IdentityAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_identity
    plug :fetch_live_flash
    plug :put_root_layout, html: {MembaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :staff_onboarding_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_identity
    plug :require_staff_identity
    plug :fetch_live_flash
    plug :put_root_layout, html: {MembaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :club_member_context do
    plug :require_active_club_member_if_club_id_present
  end

  pipeline :club_member_required do
    plug MembaWeb.Plugs.ClubSiteMemberRoute
    plug :require_active_club_member
    plug :suppress_public_footer
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :staff_mcp do
    plug MembaWeb.StaffMCP.Auth
  end

  pipeline :test_support_session do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/", MembaWeb do
    pipe_through [:browser, :club_member_context]

    get "/", PageController, :home
  end

  scope "/", MembaWeb do
    pipe_through [:browser, :club_member_required]

    live_session :club_member,
      on_mount: [{MembaWeb.IdentityAuth, :mount_current_identity}],
      session: {MembaWeb.Plugs.ClubSiteMemberRoute, :live_session, []} do
      live "/conversations", MemberDashboardLive, :conversations
      live "/members", MemberDashboardLive, :members
      live "/groups/new", MemberGroupLive.New, :new
      live "/groups/:group_id", MemberDashboardLive, :conversations
      live "/groups/:group_id/members", MemberDashboardLive, :members
      live "/groups/:group_id/members/add/:person_id", MemberDashboardLive, :targeted_add
      live "/my/settings", MySettingsLive, :profile
      live "/my/settings/profile", MySettingsLive, :profile
      live "/my/settings/clubs", MySettingsLive, :clubs
      live "/my/settings/emails", MySettingsLive, :emails
      live "/messages/new", MemberMessageLive.New, :new
      live "/messages/:message_id", MemberMessageLive.Show, :show
      live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show
      live "/members/invitations/new", MemberInvitationLive.New, :new
    end
  end

  scope "/", MembaWeb do
    pipe_through :staff_onboarding_browser

    live_session :staff_onboarding do
      live "/auth/onboard", AuthLive.Onboard
    end
  end

  scope "/", MembaWeb do
    pipe_through :browser

    live_session :auth do
      live "/auth", AuthLive.SignIn, :new
      live "/auth/check-email", AuthLive.SignIn, :sent
      live "/auth/check-email/:request_id", AuthLive.SignIn, :sent
    end

    get "/auth/sign-in/:token", AuthController, :callback

    get "/my/settings/email-verifications/:token",
        PersonEmailAddressVerificationController,
        :callback

    get "/invitations/club-members/profile", ClubMemberInvitationController, :profile
    post "/invitations/club-members/profile", ClubMemberInvitationController, :complete_profile
    get "/invitations/club-members/:token", ClubMemberInvitationController, :callback

    get "/messages/conversations/stop-following/:token",
        ConversationFollowController,
        :stop_following

    delete "/auth", AuthController, :delete
    get "/about", PageController, :about
    get "/get-started", PageController, :get_started
    post "/get-started", PageController, :submit_get_started
    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy
  end

  scope "/mcp", MembaWeb do
    pipe_through :staff_mcp

    post "/", StaffMCPController, :rpc
    get "/", StaffMCPController, :no_stream
    delete "/", StaffMCPController, :no_stream
  end

  scope "/webhooks", MembaWeb do
    pipe_through :api

    post "/postmark", PostmarkWebhookController, :create
    post "/postmark/inbound", PostmarkInboundWebhookController, :create
    post "/resend", ResendWebhookController, :create
    post "/resend/inbound", ResendInboundWebhookController, :create
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:memba, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MembaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/dev/test-support", MembaWeb do
      pipe_through :api

      post "/auth-links/expire", DevTestSupportController, :expire_auth_link

      post "/reset", DevTestSupportController, :reset_acceptance_state
      post "/seed", DevTestSupportController, :seed
      get "/stop-follow-url", DevTestSupportController, :stop_follow_url

      post "/messaging-delivery-provider",
           DevTestSupportController,
           :configure_messaging_email_delivery_provider

      get "/read-model-changes/events", DevTestSupportController, :read_model_change_events
    end

    scope "/dev/test-support", MembaWeb do
      pipe_through :test_support_session

      post "/sign-in", DevTestSupportController, :sign_in
    end
  end

  defp suppress_public_footer(conn, _opts) do
    Plug.Conn.assign(conn, :hide_public_footer, true)
  end
end
