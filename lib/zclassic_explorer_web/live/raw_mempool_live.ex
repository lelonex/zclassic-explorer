defmodule ZclassicExplorerWeb.RawMempoolLive do
  use ZclassicExplorerWeb, :live_view
  import Phoenix.LiveView.Helpers
  @impl true
  def render(assigns) do
    ~L"""
    <div class="shadow overflow-hidden border-gray-200 rounded-lg overflow-x-auto">
    <table class="w-full text-sm text-left text-gray-500 dark:text-gray-400">
      <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
      <tr>
         <th scope="col" class="px-6 py-3">Tx ID</th>
         <th scope="col" class="px-4 py-3">Block</th>
          <th scope="col" class="px-4 py-3">Time</th>
          <th scope="col" class="px-4 py-3">Fee</th>
          <th scope="col" class="px-4 py-3">Size</th>
        </tr>
       </thead>
       <tbody class="bg-white-500 divide-y divide-gray-200">
       <%= for tx <- @raw_mempool do %>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-indigo-600 hover:text-indigo-500 animate-pulse dark:text-white dark:hover:text-white">
          <a href='/transactions/<%= tx["txid"] %>'>
               <%= tx["txid"] %>
          </a>
        </td>
        <td class="px-4 py-4 whitespace-nowrap text-sm font-medium">
            <%= tx["info"]["height"] %>
          </td>
        <td class="px-4 py-4 whitespace-nowrap text-sm font-MEDI">
          <%= ZclassicExplorerWeb.BlockView.mined_time_rel(tx["info"]["time"]) %>
        </td>
        <td class="px-4 py-4 whitespace-nowrap text-sm font-medium">
         <%= ZclassicExplorerWeb.TransactionView.format_zec(tx["info"]["fee"]) %>
        </td>
        <td class="px-4 py-4 whitespace-nowrap text-sm font-medium">
          <%= tx["info"]["size"] %>
        </td>
       </tr>
      <% end %>
    </tbody>
    </table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 5000)

    case Cachex.get(:app_cache, "raw_mempool") do
      {:ok, mempool} when is_list(mempool) ->
        {:ok, assign(socket, :raw_mempool, mempool)}

      {:ok, _} ->
        {:ok, assign(socket, :raw_mempool, [])}

      {:error, _reason} ->
        {:ok, assign(socket, :raw_mempool, [])}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 5000)
    case Cachex.get(:app_cache, "raw_mempool") do
      {:ok, mempool} when is_list(mempool) ->
        {:noreply, assign(socket, :raw_mempool, mempool)}
      {:ok, _} ->
        {:noreply, assign(socket, :raw_mempool, [])}
      {:error, _} ->
        {:noreply, assign(socket, :raw_mempool, [])}
    end
  end
end
