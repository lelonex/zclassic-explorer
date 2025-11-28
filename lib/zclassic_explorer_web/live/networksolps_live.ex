defmodule ZclassicExplorerWeb.NetworkSolpsLive do
  use ZclassicExplorerWeb, :live_view
  import Phoenix.LiveView.Helpers
  @impl true
  def render(assigns) do
    ~L"""
    <p class="text-2xl font-semibold text-gray-900 dark:dark:bg-slate-800 dark:text-slate-100">
    <%= @networksolps %>
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 15000)

    case Cachex.get(:app_cache, "networksolps") do
      {:ok, info} ->
        {:ok, assign(socket, :networksolps, info)}

      _ ->
        {:ok, assign(socket, :networksolps, 0)}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 15000)
    case Cachex.get(:app_cache, "networksolps") do
      {:ok, info} ->
        {:noreply, assign(socket, :networksolps, info)}
      _ ->
        {:noreply, socket}
    end
  end
end
