defmodule BidMatch.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BidMatchWeb.TelemetryHandler,
      {DNSCluster, query: Application.get_env(:bid_match, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BidMatch.PubSub},
      {BidMatch.AdServer, []},
      {Task.Supervisor, name: BidMatch.RequestTaskSupervisor},
      {BidMatch.RequestTracker, []},
      BidMatchWeb.Endpoint
    ]

    # Conditionally add the RequestWorker if not in the test environment
    children =
      if Mix.env() == :test do
        children
      else
        children ++ [{BidMatch.RequestWorker, []}]
      end

    opts = [strategy: :one_for_one, name: BidMatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BidMatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
