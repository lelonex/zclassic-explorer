defmodule ZclassicExplorer.BlockchainScanner do
  @moduledoc """
  Scans blockchain to find transactions associated with an address.
  This is used when AddressIndex is not available on the node.
  """
  require Logger

  @doc """
  Scan recent blocks to find transactions for a given address.
  Returns a list of deltas (transaction data) and calculated balance.
  Uses caching to avoid rescanning the same blocks.
  """
  def get_address_transactions(address, scan_depth \\ 2000) do
    cache_key = "addr_txs_#{address}"
    
    # Try to get from cache first
    case Cachex.get(:app_cache, cache_key) do
      {:ok, cached_result} when not is_nil(cached_result) ->
        Logger.info("Using cached transactions for #{address}")
        cached_result
        
      _ ->
        result = do_scan_address(address, scan_depth)
        # Cache for 5 minutes
        Cachex.put(:app_cache, cache_key, result, opts: [ttl: :timer.minutes(5)])
        result
    end
  end

  defp do_scan_address(address, scan_depth) do
    case Zclassicex.getblockcount() do
      {:ok, current_height} ->
        start_height = max(0, current_height - scan_depth)
        Logger.info("Scanning blocks #{start_height}..#{current_height} for address #{address}")
        
        scan_blocks(address, start_height, current_height, [])
        
      {:error, error} ->
        Logger.warn("Failed to get block count: #{inspect(error)}")
        {[], %{"balance" => 0, "received" => 0}}
    end
  end

  defp scan_blocks(address, current, max_height, acc) when current > max_height do
    # Reverse to have chronological order, calculate balance
    deltas = Enum.reverse(acc)
    balance = calculate_balance_from_deltas(deltas)
    {deltas, balance}
  end

  defp scan_blocks(address, current, max_height, acc) do
    case get_block_txids(current) do
      {:ok, txids} ->
        new_acc = scan_txids(address, txids, current, acc)
        scan_blocks(address, current + 1, max_height, new_acc)

      {:error, error} ->
        Logger.warn("Failed to get block #{current}: #{inspect(error)}")
        scan_blocks(address, current + 1, max_height, acc)
    end
  end

  defp get_block_txids(height) do
    case Zclassicex.getblockhash(height) do
      {:ok, hash} ->
        case Zclassicex.getblock(hash) do
          {:ok, block} ->
            {:ok, Map.get(block, "tx", [])}

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp scan_txids(address, txids, block_height, acc) do
    Enum.reduce(txids, acc, fn txid, acc ->
      case analyze_transaction(txid, address, block_height) do
        nil -> acc
        delta -> [delta | acc]
      end
    end)
  end

  defp analyze_transaction(txid, address, block_height) do
    case Zclassicex.getrawtransaction(txid) do
      {:ok, raw_tx} ->
        case Zclassicex.decoderawtransaction(raw_tx) do
          {:ok, tx} ->
            find_address_in_transaction(tx, address, txid, block_height)

          {:error, error} ->
            Logger.warn("Failed to decode transaction #{txid}: #{inspect(error)}")
            nil
        end

      {:error, error} ->
        Logger.warn("Failed to get raw transaction #{txid}: #{inspect(error)}")
        nil
    end
  end

  defp find_address_in_transaction(tx, address, txid, block_height) do
    # Check outputs first (receiving transactions)
    outputs = Map.get(tx, "vout", [])
    
    output_match =
      Enum.find_value(outputs, fn output ->
        script_pubkey = Map.get(output, "scriptPubKey", %{})
        addresses = Map.get(script_pubkey, "addresses", [])
        
        if Enum.member?(addresses, address) do
          satoshis = trunc(Map.get(output, "value", 0) * 100_000_000)
          %{
            "txid" => txid,
            "satoshis" => satoshis,
            "amount" => Map.get(output, "value", 0),
            "blockheight" => block_height,
            "type" => "output"
          }
        end
      end)

    if output_match do
      output_match
    else
      # Check inputs (sending transactions)
      inputs = Map.get(tx, "vin", [])
      
      Enum.find_value(inputs, nil, fn input ->
        prev_txid = Map.get(input, "txid")
        prev_vout = Map.get(input, "vout")
        
        case get_input_address(prev_txid, prev_vout) do
          {:ok, input_address} when input_address == address ->
            # Need to get the value from the previous output
            case Zclassicex.getrawtransaction(prev_txid) do
              {:ok, prev_raw} ->
                case Zclassicex.decoderawtransaction(prev_raw) do
                  {:ok, prev_tx} ->
                    prev_outputs = Map.get(prev_tx, "vout", [])
                    
                    case Enum.at(prev_outputs, prev_vout) do
                      nil ->
                        nil

                      output ->
                        satoshis = trunc(Map.get(output, "value", 0) * 100_000_000)
                        
                        %{
                          "txid" => txid,
                          "satoshis" => -satoshis,
                          "amount" => -Map.get(output, "value", 0),
                          "blockheight" => block_height,
                          "type" => "input"
                        }
                    end

                  {:error, _} ->
                    nil
                end

              {:error, _} ->
                nil
            end

          _ ->
            nil
        end
      end)
    end
  end

  defp get_input_address(txid, vout) do
    case Zclassicex.getrawtransaction(txid) do
      {:ok, raw_tx} ->
        case Zclassicex.decoderawtransaction(raw_tx) do
          {:ok, tx} ->
            outputs = Map.get(tx, "vout", [])
            
            case Enum.at(outputs, vout) do
              nil ->
                {:error, :invalid_vout}

              output ->
                script_pubkey = Map.get(output, "scriptPubKey", %{})
                addresses = Map.get(script_pubkey, "addresses", [])
                
                case addresses do
                  [addr] -> {:ok, addr}
                  _ -> {:error, :multiple_addresses}
                end
            end

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp calculate_balance_from_deltas(deltas) when is_list(deltas) do
    deltas
    |> Enum.reduce(%{"balance" => 0, "received" => 0}, fn delta, acc ->
      satoshis = Map.get(delta, "satoshis", 0)
      
      received = acc["received"] + abs(satoshis)
      balance = acc["balance"] + satoshis
      
      %{"balance" => balance, "received" => received}
    end)
  end

  defp calculate_balance_from_deltas(_), do: %{"balance" => 0, "received" => 0}
end
