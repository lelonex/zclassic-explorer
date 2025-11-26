defmodule ZclassicExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Cachex.Spec

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # ZclassicExplorer.Repo,
      # Start the Telemetry supervisor
      ZclassicExplorerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ZclassicExplorer.PubSub},
      # Start the Endpoint (http/https)
      ZclassicExplorerWeb.Endpoint,
      # Start a worker by calling: ZclassicExplorer.Worker.start_link(arg)
      %{
        id: Zclassicex,
        start:
          {Zclassicex, :start_link,
           [
             Application.get_env(:zclassic_explorer, Zclassicex)[:zclassicd_hostname],
             String.to_integer(Application.get_env(:zclassic_explorer, Zclassicex)[:zclassicd_port]),
             Application.get_env(:zclassic_explorer, Zclassicex)[:zclassicd_username],
             Application.get_env(:zclassic_explorer, Zclassicex)[:zclassicd_password]
           ]}
      },
      {Cachex,
       name: :app_cache,
       warmers: [
         warmer(module: ZclassicExplorer.Metrics.MetricsWarmer, state: {}),
         warmer(module: ZclassicExplorer.Metrics.MempoolInfoWarmer, state: {}),
         warmer(module: ZclassicExplorer.Metrics.NetworkSolpsWarmer, state: {}),
         warmer(module: ZclassicExplorer.Blocks.BlockWarmer, state: {}),
         warmer(module: ZclassicExplorer.Transactions.TransactionWarmer, state: {}),
         warmer(module: ZclassicExplorer.Mempool.MempoolWarmer, state: {}),
         warmer(module: ZclassicExplorer.Nodes.NodeWarmer, state: {}),
         warmer(module: ZclassicExplorer.Metrics.InfoWarmer, state: {})
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ZclassicExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ZclassicExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
