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
      Memba.Membership.App,
      Memba.Messaging.App,
      Memba.Messaging.DeliveryProviders.Fake,
      Memba.Messaging.Projectors.Message,
      Memba.Messaging.Projectors.RecipientDelivery,
      Memba.Messaging.Projectors.MemberReceipt,
      Memba.Messaging.Projectors.OperatorDeliverability,
      Memba.Membership.Projectors.Club,
      Memba.Membership.Projectors.Membership,
      Memba.Membership.Projectors.Person,
      {DNSCluster, query: Application.get_env(:memba, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Memba.PubSub},
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
