defmodule Memba.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MembaWeb.Telemetry,
      Memba.Repo,
      {Phoenix.PubSub, name: Memba.PubSub},
      Memba.Membership.App,
      Memba.Messaging.App,
      Memba.Messaging.EmailDeliveryProviders.Fake,
      Memba.Messaging.LocalDeliveryFacts,
      {Memba.Messaging.EmailDeliveryDispatcher,
       dispatch_enabled:
         Application.get_env(:memba, :email_delivery_dispatcher_dispatch_enabled, true)},
      Memba.Messaging.Projectors.Message,
      Memba.Messaging.Projectors.ConversationFollow,
      Memba.Messaging.Projectors.EmailDelivery,
      Memba.Messaging.Projectors.MemberEmailDelivery,
      Memba.Messaging.Projectors.MembaStaffEmailDelivery,
      Memba.Messaging.Projectors.InboundEmailSource,
      Memba.Membership.Projectors.Club,
      Memba.Membership.Projectors.ClubInvitation,
      Memba.Membership.Projectors.Membership,
      Memba.Membership.Projectors.Group,
      Memba.Membership.Projectors.GroupMembership,
      Memba.Membership.Projectors.Role,
      Memba.Membership.Projectors.Person,
      Memba.Membership.Policies.SystemGroupMembership,
      {DNSCluster, query: Application.get_env(:memba, :dns_cluster_query) || :ignore},
      # Start a worker by calling: Memba.Worker.start_link(arg)
      # {Memba.Worker, arg},
      # Start to serve requests, typically the last entry
      MembaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Memba.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MembaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
