defmodule RubberduckWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RubberduckWebWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:rubberduck_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RubberduckWeb.PubSub},
      # Start Presence for tracking users in collaborative sessions
      RubberduckWebWeb.Presence,
      # Start a worker by calling: RubberduckWeb.Worker.start_link(arg)
      # {RubberduckWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      RubberduckWebWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :rubberduck_web]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RubberduckWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RubberduckWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
