defmodule MembaWeb.Router do
  use MembaWeb, :router

  import MembaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_identity
    plug :fetch_live_flash
    plug :put_root_layout, html: {MembaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :staff_browser do
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
    plug :require_active_club_member
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MembaWeb do
    pipe_through [:browser, :club_member_context]

    get "/", PageController, :home
    post "/", PageController, :send_message
  end

  scope "/", MembaWeb do
    pipe_through [:browser, :club_member_required]

    live_session :club_member, on_mount: [{MembaWeb.UserAuth, :mount_current_identity}] do
      live "/messages/:message_id", MemberMessageLive.Show, :show
    end
  end

  scope "/", MembaWeb do
    pipe_through :browser

    get "/auth", AuthController, :new
    post "/auth", AuthController, :create
    get "/auth/magic/:token", AuthController, :callback
    delete "/auth", AuthController, :delete
    get "/about", PageController, :about
    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy
  end

  scope "/admin", MembaWeb.Admin do
    pipe_through :staff_browser

    live_session :staff_admin, on_mount: [{MembaWeb.UserAuth, :require_staff_identity}] do
      live "/clubs", ClubsLive.Index
      live "/clubs/:club_id", ClubsLive.Show
      live "/deliveries", DeliveriesLive.Index
      live "/messages/:message_id", MessagesLive.Show
    end
  end

  scope "/webhooks", MembaWeb do
    pipe_through :api

    post "/postmark", PostmarkWebhookController, :create
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
    end
  end
end
