defmodule ZclassicExplorer.RichList.RichListUpdater do
  @moduledoc """
  GenServer that periodically updates the rich list by scanning blockchain addresses.
  Uses CubDB for persistent storage and caches results.
  """
  use GenServer
  require Logger

  @update_interval :timer.hours(6) # Update every 6 hours
  @db_path "priv/rich_list.db"
  @cache_key "rich_list_data"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    # Start CubDB
    {:ok, db} = CubDB.start_link(data_dir: @db_path)
    
    # Load existing data or start fresh
    initial_data = case CubDB.get(db, :rich_list) do
      nil -> []
      list -> list
    end
    
    # Cache initial data
    Cachex.put(:app_cache, @cache_key, initial_data)
    
    # Schedule first update after 1 minute
    Process.send_after(self(), :update, :timer.minutes(1))
    
    Logger.info("RichListUpdater started - will update every 6 hours")
    
    {:ok, %{db: db, addresses: initial_data}}
  end

  @impl true
  def handle_info(:update, state) do
    Logger.info("Starting rich list update...")
    
    # Get all addresses with balances
    addresses = fetch_rich_addresses()
    
    # Sort by balance descending and take top 100
    top_100 = addresses
    |> Enum.sort_by(fn addr -> addr["balance"] end, :desc)
    |> Enum.take(100)
    |> Enum.with_index(1)
    |> Enum.map(fn {addr, rank} -> Map.put(addr, "rank", rank) end)
    
    # Store in CubDB
    CubDB.put(state.db, :rich_list, top_100)
    CubDB.put(state.db, :last_updated, DateTime.utc_now())
    
    # Update cache
    Cachex.put(:app_cache, @cache_key, top_100)
    
    Logger.info("Rich list updated: #{length(top_100)} addresses")
    
    # Schedule next update
    Process.send_after(self(), :update, @update_interval)
    
    {:noreply, %{state | addresses: top_100}}
  end

  @impl true
  def terminate(_reason, state) do
    CubDB.stop(state.db)
    :ok
  end

  # Fetch addresses with balances from the blockchain
  # This scans recent blocks and aggregates address balances
  defp fetch_rich_addresses do
    # Get current block height
    case Zclassicex.getinfo() do
      {:ok, info} ->
        block_height = info["blocks"]
        
        # Scan last 10000 blocks to get address activity
        # In a production system, this should be a complete UTXO set scan
        scan_recent_blocks(block_height, 10_000)
        
      {:error, _reason} ->
        Logger.warn("Failed to fetch blockchain info for rich list")
        []
    end
  end

  defp scan_recent_blocks(current_height, blocks_to_scan) do
    start_height = max(0, current_height - blocks_to_scan)
    
    # Build address balance map
    address_balances = Enum.reduce(start_height..current_height, %{}, fn height, acc ->
      case get_block_addresses(height) do
        {:ok, addresses} ->
          Enum.reduce(addresses, acc, fn {address, balance}, addr_acc ->
            Map.update(addr_acc, address, balance, fn existing -> existing + balance end)
          end)
        _ ->
          acc
      end
    end)
    
    # Convert to list format
    address_balances
    |> Enum.map(fn {address, balance} ->
      %{
        "address" => address,
        "balance" => balance,
        "tx_count" => get_address_tx_count(address)
      }
    end)
    |> Enum.filter(fn addr -> addr["balance"] > 0 end)
  end

  defp get_block_addresses(height) do
    case Zclassicex.getblockhash(height) do
      {:ok, hash} ->
        case Zclassicex.getblock(hash, 2) do
          {:ok, block} ->
            addresses = extract_addresses_from_block(block)
            {:ok, addresses}
          _ ->
            {:error, :block_fetch_failed}
        end
      _ ->
        {:error, :hash_fetch_failed}
    end
  end

  defp extract_addresses_from_block(block) do
    transactions = block["tx"] || []
    
    Enum.flat_map(transactions, fn tx ->
      # Extract from vout (outputs)
      vout = tx["vout"] || []
      
      Enum.flat_map(vout, fn output ->
        case output["scriptPubKey"]["addresses"] do
          [address | _] when is_binary(address) ->
            value = output["value"] || 0
            [{address, value}]
          _ ->
            []
        end
      end)
    end)
  end

  defp get_address_tx_count(_address) do
    # Placeholder - would need full address index
    # For now return estimated count
    1
  end
end
