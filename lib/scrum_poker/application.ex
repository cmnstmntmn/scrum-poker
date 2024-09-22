defmodule ScrumPoker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScrumPokerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:scrum_poker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScrumPoker.PubSub},
      ScrumPokerWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: ScrumPoker.Finch},
      # Start a worker by calling: ScrumPoker.Worker.start_link(arg)
      # {ScrumPoker.Worker, arg},
      # Start to serve requests, typically the last entry
      ScrumPokerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScrumPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScrumPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
