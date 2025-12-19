defmodule CalmdoPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CalmdoPhoenixWeb.Telemetry,
      CalmdoPhoenix.Repo,
      {DNSCluster, query: Application.get_env(:calmdo_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CalmdoPhoenix.PubSub},
      # Start a worker by calling: CalmdoPhoenix.Worker.start_link(arg)
      # {CalmdoPhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      CalmdoPhoenixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CalmdoPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CalmdoPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
