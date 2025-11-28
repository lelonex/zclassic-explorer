defmodule ZclassicExplorerWeb.PriceLive do
  use ZclassicExplorerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 30_000)

    price_data = case Cachex.get(:app_cache, "zcl_price") do
      {:ok, data} when not is_nil(data) -> data
      _ -> %{usd: 0, btc: 0, usd_24h_change: 0, market_cap_usd: 0, total_volume_usd: 0, markets: []}
    end

    {:ok, assign(socket, price_data: price_data)}
  end

  @impl true
  def render(assigns) do
    # Calculate real volume from markets
    markets = Map.get(assigns.price_data, "markets") || Map.get(assigns.price_data, :markets) || []
    markets_volume = if markets && length(markets) > 0 do
      markets
      |> Enum.map(fn m -> Map.get(m, "converted_volume", %{}) |> Map.get("usd", 0) end)
      |> Enum.sum()
    else
      Map.get(assigns.price_data, "total_volume_usd") || Map.get(assigns.price_data, :total_volume_usd) || 0
    end
    
    assigns = assign(assigns, :calculated_volume, markets_volume)
    
    ~H"""
    <div x-data="{ open: false }" class="bg-white dark:bg-gray-800 rounded-lg shadow">
      <button @click="open = !open" class="w-full flex justify-between items-center p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
        <div class="flex items-center space-x-4">
          <h2 class="text-xl font-bold text-gray-900 dark:text-white">💰 ZCL Price</h2>
          <span class="text-2xl font-bold text-green-600 dark:text-green-400">
            $<%= Float.round((Map.get(@price_data, "usd") || Map.get(@price_data, :usd) || 0) * 1.0, 4) %>
          </span>
          <%= if Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) do %>
            <span class={"text-sm font-medium px-2 py-1 rounded #{if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200", else: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"}"}>
              <%= if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "▲", else: "▼" %> 
              <%= Float.round(abs((Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) * 1.0), 2) %>%
            </span>
          <% end %>
          <span class="text-sm text-gray-500 dark:text-gray-400">
            ₿ <%= Float.round((Map.get(@price_data, "btc") || Map.get(@price_data, :btc) || 0) * 1.0, 8) %>
          </span>
        </div>
        <svg x-show="!open" class="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
        <svg x-show="open" class="w-6 h-6 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path>
        </svg>
      </button>
      
      <div x-show="open" x-transition class="p-6 pt-0 border-t border-gray-200 dark:border-gray-700">
      
      <!-- Price Display -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div class="bg-gradient-to-br from-orange-50 to-orange-100 dark:from-orange-900 dark:to-orange-800 p-4 rounded-lg">
          <p class="text-sm text-gray-600 dark:text-gray-300 mb-1">USD Price</p>
          <p class="text-3xl font-bold text-orange-600 dark:text-orange-400">
            $<%= Float.round((Map.get(@price_data, "usd") || Map.get(@price_data, :usd) || 0) * 1.0, 6) %>
          </p>
          <%= if Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) do %>
            <p class={"text-sm mt-2 #{if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "text-green-600", else: "text-red-600"}"}>
              <%= if (Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) >= 0, do: "▲", else: "▼" %> 
              <%= Float.round(abs((Map.get(@price_data, "usd_24h_change") || Map.get(@price_data, :usd_24h_change) || 0) * 1.0), 2) %>% (24h)
            </p>
          <% end %>
        </div>

        <div class="bg-gradient-to-br from-yellow-50 to-yellow-100 dark:from-yellow-900 dark:to-yellow-800 p-4 rounded-lg">
          <p class="text-sm text-gray-600 dark:text-gray-300 mb-1">BTC Price</p>
          <p class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">
            ₿ <%= Float.round((Map.get(@price_data, "btc") || Map.get(@price_data, :btc) || 0) * 1.0, 8) %>
          </p>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">Satoshis: <%= trunc((Map.get(@price_data, "btc") || Map.get(@price_data, :btc) || 0) * 100_000_000) %></p>
        </div>
      </div>

      <!-- Market Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <p class="text-sm text-gray-600 dark:text-gray-400">Market Cap</p>
          <p class="text-xl font-semibold text-gray-900 dark:text-white">
            $<%= format_large_number(Map.get(@price_data, "market_cap_usd") || Map.get(@price_data, :market_cap_usd) || 0) %>
          </p>
        </div>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <p class="text-sm text-gray-600 dark:text-gray-400">24h Volume (sum from exchanges)</p>
          <p class="text-xl font-semibold text-gray-900 dark:text-white">
            $<%= format_large_number(@calculated_volume) %>
          </p>
        </div>
      </div>

      <!-- Markets Table -->
      <%= if (Map.get(@price_data, "markets") || Map.get(@price_data, :markets) || []) && length(Map.get(@price_data, "markets") || Map.get(@price_data, :markets) || []) > 0 do %>
        <div class="mt-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Top Markets</h3>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead class="bg-gray-50 dark:bg-gray-900">
                <tr>
                  <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">Exchange</th>
                  <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">Pair</th>
                  <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">Price</th>
                  <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">24h Volume</th>
                  <th class="px-4 py-2 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">Trust</th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                <%= for market <- Enum.take(Map.get(@price_data, "markets") || Map.get(@price_data, :markets) || [], 10) do %>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                    <td class="px-4 py-2 text-sm text-gray-900 dark:text-white">
                      <%= if Map.get(market, "url") || Map.get(market, :url) do %>
                        <a href={Map.get(market, "url") || Map.get(market, :url)} target="_blank" rel="noopener" class="text-orange-600 hover:text-orange-700 dark:text-orange-400">
                          <%= Map.get(market, "exchange") || Map.get(market, :exchange) %>
                        </a>
                      <% else %>
                        <%= Map.get(market, "exchange") || Map.get(market, :exchange) %>
                      <% end %>
                    </td>
                    <td class="px-4 py-2 text-sm text-gray-600 dark:text-gray-400"><%= Map.get(market, "pair") || Map.get(market, :pair) %></td>
                    <td class="px-4 py-2 text-sm text-right font-mono text-gray-900 dark:text-white">
                      $<%= Float.round(Map.get(market, "price") || Map.get(market, :price) || 0, 6) %>
                    </td>
                    <td class="px-4 py-2 text-sm text-right text-gray-600 dark:text-gray-400">
                      $<%= format_large_number(Map.get(market, "volume_24h") || Map.get(market, :volume_24h) || 0) %>
                    </td>
                    <td class="px-4 py-2 text-sm text-center">
                      <span class={"px-2 py-1 rounded text-xs font-medium #{trust_score_color(Map.get(market, "trust_score") || Map.get(market, :trust_score))}"}>
                        <%= String.upcase(Map.get(market, "trust_score") || Map.get(market, :trust_score) || "N/A") %>
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

      <p class="text-xs text-gray-500 dark:text-gray-400 mt-4">
        Data from CoinGecko • Updated every 5 minutes
      </p>
      </div>
    </div>
    """
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

  defp format_large_number(nil), do: "0"
  defp format_large_number(num) when is_number(num) and num >= 1_000_000 do
    "#{Float.round(num / 1_000_000 * 1.0, 2)}M"
  end
  defp format_large_number(num) when is_number(num) and num >= 1_000 do
    "#{Float.round(num / 1_000 * 1.0, 2)}K"
  end
  defp format_large_number(num) when is_number(num), do: Float.round(num * 1.0, 2)
  defp format_large_number(_), do: "0"

  defp trust_score_color("green"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp trust_score_color("yellow"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp trust_score_color(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
end
