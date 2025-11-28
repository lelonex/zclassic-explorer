defmodule ZclassicExplorer.Transactions.TransactionWarmer do
  use Cachex.Warmer
  require Logger

  @doc """
  Returns the interval for this warmer.
  """
  def interval,
    do: :timer.seconds(15)

  @doc """
  Executes this cache warmer.
  """
  def execute(_state) do
    case Zclassicex.getblockcount() do
      {:ok, height} when is_integer(height) ->
        # Prendi le transazioni dagli ultimi 5 blocchi
        _txs = for h <- height..(max(height - 4, 1)), h > 0 do
          case Zclassicex.getblockhash(h) do
            {:ok, hash} ->
              case Zclassicex.getblock(hash, 2) do
                {:ok, block} when is_map(block) ->
                  block_txs = Map.get(block, "tx", [])
                  block_txs
                  |> Enum.take(5)  # Max 5 tx per blocco
                  |> Enum.map(fn tx when is_map(tx) ->
                    %{
                      "txid" => Map.get(tx, "txid"),
                      "block_height" => h,
                      "time" => format_time(Map.get(tx, "time") || Map.get(block, "time")),
                      "tx_out_total" => calculate_tx_output(tx),
                      "size" => Map.get(tx, "size", 0),
                      "type" => get_tx_type(tx)
                    }
                  end)
                _ -> []
              end
            _ -> []
          end
        end
        |> List.flatten()
        |> Enum.take(10)
        |> handle_result

      {:error, reason} ->
        Logger.error("TransactionWarmer error: #{inspect(reason)}")
        :ignore
    end
  end

  defp format_time(nil), do: "Unknown"
  defp format_time(timestamp) when is_integer(timestamp) do
    abs = timestamp |> Timex.from_unix() |> Timex.format!("{ISOdate} {ISOtime}")
    rel = timestamp |> Timex.from_unix() |> Timex.format!("{relative}", :relative)
    abs <> " (" <> rel <> ")"
  end
  defp format_time(_), do: "Unknown"

  defp calculate_tx_output(tx) when is_map(tx) do
    vout = Map.get(tx, "vout", [])
    result = vout
    |> Enum.reduce(0, fn v, acc -> 
      value = Map.get(v, "value", 0) || 0
      acc + value
    end)
    result * 1.0 |> Float.to_string()
  end
  defp calculate_tx_output(_), do: "0"

  defp get_tx_type(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    _vout = Map.get(tx, "vout", [])
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vShieldedSpend = Map.get(tx, "vShieldedSpend", [])
    vShieldedOutput = Map.get(tx, "vShieldedOutput", [])

    has_coinbase = Enum.any?(vin, fn v -> Map.has_key?(v, "coinbase") end)
    has_shielded = length(vjoinsplit) > 0 or length(vShieldedSpend) > 0 or length(vShieldedOutput) > 0

    cond do
      has_coinbase -> "coinbase"
      has_shielded -> "shielded"
      true -> "transparent"
    end
  end
  defp get_tx_type(_), do: "unknown"

  defp handle_result(info) when is_list(info) do
    Logger.debug("TransactionWarmer cached #{length(info)} transactions")
    {:ok, [{"transaction_cache", info}]}
  end
end
