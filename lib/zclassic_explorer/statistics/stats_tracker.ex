defmodule ZclassicExplorer.Statistics.StatsTracker do
  @moduledoc """
  GenServer that tracks historical statistics using CubDB.
  Records daily snapshots of network metrics.
  """
  use GenServer
  require Logger

  @update_interval :timer.hours(1) # Update every hour
  @db_path "priv/statistics.db"
  @cache_key "statistics_data"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    # Start CubDB
    {:ok, db} = CubDB.start_link(data_dir: @db_path)
    
    # Load existing stats
    stats = load_statistics(db)
    
    # Cache stats
    Cachex.put(:app_cache, @cache_key, stats)
    
    # Schedule first update
    Process.send_after(self(), :update, :timer.seconds(30))
    
    Logger.info("StatsTracker started")
    
    {:ok, %{db: db, stats: stats}}
  end

  @impl true
  def handle_info(:update, state) do
    current_stats = collect_current_stats()
    
    # Get today's date as key
    date_key = Date.utc_today() |> Date.to_string()
    
    # Store in CubDB
    CubDB.put(state.db, date_key, current_stats)
    CubDB.put(state.db, :latest, current_stats)
    
    # Load full history
    stats = load_statistics(state.db)
    
    # Update cache
    Cachex.put(:app_cache, @cache_key, stats)
    
    Logger.debug("Statistics updated for #{date_key}")
    
    # Schedule next update
    Process.send_after(self(), :update, @update_interval)
    
    {:noreply, %{state | stats: stats}}
  end

  @impl true
  def terminate(_reason, state) do
    CubDB.stop(state.db)
    :ok
  end

  defp load_statistics(db) do
    # Get latest stats
    latest = CubDB.get(db, :latest) || %{}
    
    # Get historical data (last 30 days)
    history = get_historical_data(db, 30)
    
    %{
      latest: latest,
      history: history,
      charts: calculate_chart_data(history)
    }
  end

  defp get_historical_data(db, days) do
    today = Date.utc_today()
    
    for i <- 0..(days - 1), reduce: [] do
      acc ->
        date = Date.add(today, -i) |> Date.to_string()
        case CubDB.get(db, date) do
          nil -> acc
          data -> [Map.put(data, :date, date) | acc]
        end
    end
  end

  defp collect_current_stats do
    with {:ok, info} <- Zclassicex.getinfo(),
         {:ok, blockchain_info} <- Zclassicex.getblockchaininfo(),
         {:ok, mempool_info} <- Zclassicex.getmempoolinfo(),
         {:ok, network_info} <- Zclassicex.getnetworkinfo() do
      
      %{
        timestamp: DateTime.utc_now() |> DateTime.to_unix(),
        block_height: info["blocks"] || 0,
        difficulty: info["difficulty"] || 0,
        total_supply: blockchain_info["moneysupply"] || 0,
        connections: info["connections"] || 0,
        mempool_size: mempool_info["size"] || 0,
        mempool_bytes: mempool_info["bytes"] || 0,
        hashrate: calculate_network_hashrate(info),
        chain_size: blockchain_info["size_on_disk"] || 0,
        version: network_info["version"] || 0,
        protocol_version: network_info["protocolversion"] || 0,
        blocks_per_day: 576, # Approximate: 144 blocks * 4 (2.5 min blocks)
        avg_block_time: 150 # 2.5 minutes in seconds
      }
    else
      {:error, reason} ->
        Logger.warn("Failed to collect stats: #{inspect(reason)}")
        %{
          timestamp: DateTime.utc_now() |> DateTime.to_unix(),
          error: reason
        }
    end
  end

  defp calculate_network_hashrate(info) do
    # Estimate network hashrate from difficulty
    # Hashrate ≈ difficulty * 2^32 / block_time
    difficulty = info["difficulty"] || 0
    block_time = 150 # 2.5 minutes
    
    (difficulty * :math.pow(2, 32) / block_time) / 1_000_000_000 # Convert to GH/s
  end

  defp calculate_chart_data(history) when is_list(history) do
    %{
      block_heights: Enum.map(history, fn h -> Map.get(h, "block_height") || Map.get(h, :block_height) end),
      difficulties: Enum.map(history, fn h -> Map.get(h, "difficulty") || Map.get(h, :difficulty) end),
      hashrates: Enum.map(history, fn h -> Map.get(h, "hashrate") || Map.get(h, :hashrate) end),
      mempool_sizes: Enum.map(history, fn h -> Map.get(h, "mempool_size") || Map.get(h, :mempool_size) end),
      dates: Enum.map(history, fn h -> Map.get(h, "date") || Map.get(h, :date, "") end)
    }
  end

  defp calculate_chart_data(_), do: %{}
end
