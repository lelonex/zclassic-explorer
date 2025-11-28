defmodule ZclassicExplorer.Blocks.BlockWarmer do
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
        # Prendi gli ultimi 10 blocchi, partendo dal più recente
        blocks = 
          Enum.map((max(height - 9, 1))..height, fn h ->
            case Zclassicex.getblockhash(h) do
              {:ok, hash} ->
                case Zclassicex.getblock(hash, 2) do
                  {:ok, block} when is_map(block) ->
                    tx_list = Map.get(block, "tx", [])
                    %{
                      "height" => Map.get(block, "height"),
                      "size" => Map.get(block, "size"),
                      "hash" => Map.get(block, "hash"),
                      "time" => format_time(Map.get(block, "time")),
                      "tx_count" => length(tx_list),
                      "output_total" => calculate_output_total(tx_list)
                    }
                  _ -> nil
                end
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.reverse()
        
        handle_result(blocks)

      {:error, reason} ->
        Logger.error("BlockWarmer error: #{inspect(reason)}")
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

  defp calculate_output_total(txs) when is_list(txs) do
    result = txs
    |> Enum.flat_map(fn tx -> Map.get(tx, "vout", []) end)
    |> Enum.reduce(0, fn vout, acc -> 
      value = Map.get(vout, "value", 0) || 0
      acc + value
    end)
    result * 1.0 |> Float.to_string()
  end
  defp calculate_output_total(_), do: "0"

  defp handle_result(info) when is_list(info) do
    Logger.debug("BlockWarmer cached #{length(info)} blocks")
    {:ok, [{"block_cache", info}]}
  end
end
