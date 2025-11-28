defmodule ZclassicExplorerWeb.Plugs.ConfigInjector do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    zclassic_network = Application.get_env(:zclassic_explorer, Zclassicex)[:zclassic_network]
    assign(conn, :zclassic_network, zclassic_network)
  end
end
