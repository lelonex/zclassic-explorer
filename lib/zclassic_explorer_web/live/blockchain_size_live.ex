defmodule ZclassicExplorerWeb.BlockChainSizeLive do
  use ZclassicExplorerWeb, :live_view
  import Phoenix.LiveView.Helpers
  @impl true
  def render(assigns) do
    ~L"""
    <p class="text-2xl font-semibold text-gray-900 dark:dark:bg-slate-800 dark:text-slate-100">
    <%= Sizeable.filesize(@blockchain_size || 0) %>
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 15000)

    case Cachex.get(:app_cache, "metrics") do
      {:ok, info} ->
        {:ok, assign(socket, :blockchain_size, info["size_on_disk"])}

      {:error, _reason} ->
        {:ok, assign(socket, :blockchain_size, 0)}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 15000)
    case Cachex.get(:app_cache, "metrics") do
      {:ok, info} when is_map(info) ->
        {:noreply, assign(socket, :blockchain_size, info["size_on_disk"])}
      _ ->
        {:noreply, socket}
    end
  end
end
