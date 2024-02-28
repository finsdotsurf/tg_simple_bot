defmodule Kujibot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KujibotWeb.Telemetry,
      Kujibot.Repo,
      {DNSCluster, query: Application.get_env(:kujibot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kujibot.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Kujibot.Finch},
      # Start a worker by calling: Kujibot.Worker.start_link(arg)
      # {Kujibot.Worker, arg},
      # Start to serve requests, typically the last entry
      KujibotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kujibot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KujibotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
