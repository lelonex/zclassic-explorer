defmodule ZclassicExplorerWeb.PriceBadgeLive do
  use ZclassicExplorerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 30_000)

    price_data = case Cachex.get(:app_cache, "zcl_price") do
      {:ok, data} when not is_nil(data) -> data
      _ -> %{usd: 0, btc: 0, usd_24h_change: 0}
    end

    {:ok, assign(socket, price_data: price_data)}
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 30_000)

    price_data = case Cachex.get(:app_cache, "zcl_price") do
      {:ok, data} when not is_nil(data) -> data
      _ -> socket.assigns.price_data
    end

    {:noreply, assign(socket, price_data: price_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <a href="/market" class="flex items-center space-x-1 px-2 py-1 rounded-md bg-green-700 dark:bg-gray-700 hover:bg-green-800 dark:hover:bg-gray-600 transition cursor-pointer">
      <span class="text-xs text-green-200 dark:text-gray-400">ZCL</span>
      <span class="text-sm font-bold text-white">
        $<%= Float.round((Map.get(@price_data, "usd") || Map.get(@price_data, :usd) || 0) * 1.0, 2) %>
      </span>
      <%= if Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) do %>
        <span class={"text-xs font-medium #{if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "text-green-200", else: "text-red-300"}"}>
          <%= if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "▲", else: "▼" %><%= Float.round(abs((Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) * 1.0), 1) %>%
        </span>
      <% end %>
    </a>
    """
  end
end
