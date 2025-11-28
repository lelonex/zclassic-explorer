defmodule ZclassicExplorerWeb.MempoolInfoLive do
  use ZclassicExplorerWeb, :live_view
  import Phoenix.LiveView.Helpers
  @impl true
  def render(assigns) do
    ~L"""
    <p class="text-2xl font-semibold text-gray-900 dark:dark:bg-slate-800 dark:text-slate-100">
    <%= case assigns.mempool_info do
      %{"size" => size} -> size
      %{"bytes" => bytes} -> bytes
      info when is_map(info) -> Map.get(info, "size", Map.get(info, "bytes", 0))
      _ -> 0
    end %>
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 15000)

    case Cachex.get(:app_cache, "mempool_info") do
      {:ok, info} ->
        {:ok, assign(socket, :mempool_info, info)}

      _ ->
        {:ok, assign(socket, :mempool_info, %{})}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 15000)
    case Cachex.get(:app_cache, "mempool_info") do
      {:ok, info} ->
        {:noreply, assign(socket, :mempool_info, info)}
      _ ->
        {:noreply, socket}
    end
  end
end
