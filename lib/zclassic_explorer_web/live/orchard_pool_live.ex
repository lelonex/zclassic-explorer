defmodule ZclassicExplorerWeb.OrchardPoolLive do
  use ZclassicExplorerWeb, :live_view
  import Phoenix.LiveView.Helpers
  @impl true
  def render(assigns) do
    currency = "ZCL"

    ~L"""
    <p class="text-2xl font-semibold text-gray-900 dark:dark:bg-slate-800 dark:text-slate-100">
    <%= orchard_value(@blockchain_info["valuePools"]) %> <%= currency %>
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 15000)

    case Cachex.get(:app_cache, "metrics") do
      {:ok, info} when is_map(info) ->
        case Cachex.get(:app_cache, "info") do
          {:ok, %{"build" => build}} ->
            info = Map.put(info, "build", build)
            {:ok, assign(socket, :blockchain_info, info)}
          _ ->
            {:ok, assign(socket, :blockchain_info, info)}
        end

      _ ->
        {:ok, assign(socket, :blockchain_info, %{})}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 15000)
    
    case Cachex.get(:app_cache, "metrics") do
      {:ok, info} when is_map(info) ->
        case Cachex.get(:app_cache, "info") do
          {:ok, %{"build" => build}} ->
            info = Map.put(info, "build", build)
            {:noreply, assign(socket, :blockchain_info, info)}
          _ ->
            {:noreply, assign(socket, :blockchain_info, info)}
        end
      _ ->
        {:noreply, socket}
    end
  end

  defp orchard_value(value_pools) when is_list(value_pools) do
    value_pools |> get_value_pools |> Map.get("orchard", 0.0)
  end
  
  defp orchard_value(_), do: 0.0

  defp get_value_pools(value_pools) when is_list(value_pools) do
    Enum.map(value_pools, fn 
      %{"id" => name, "chainValue" => value} -> {name, value}
      _ -> {"unknown", 0.0}
    end)
    |> Map.new()
  end
end
