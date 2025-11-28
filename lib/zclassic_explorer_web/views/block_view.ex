defmodule ZclassicExplorerWeb.BlockView do
  alias ZclassicExplorerWeb.TransactionView
  use ZclassicExplorerWeb, :view

  def zcash_network do
    Application.get_env(:zclassic_explorer, Zclassicex)[:zcash_network] || "mainnet"
  end

  def mined_time(nil) do
    "Not yet mined"
  end

  def mined_time(timestamp) do
    abs = timestamp |> Timex.from_unix() |> Timex.format!("{ISOdate} {ISOtime}")
    rel = timestamp |> Timex.from_unix() |> Timex.format!("{relative}", :relative)
    abs <> " " <> "(#{rel})"
  end

  def mined_time_without_rel(timestamp) do
    timestamp |> Timex.from_unix() |> Timex.format!("{ISOdate} {ISOtime}")
  end

  def mined_time_rel(timestamp) do
    timestamp |> Timex.from_unix() |> Timex.format!("{relative}", :relative)
  end

  def transaction_count(txs) do
    txs |> length
  end

  def vin_count(txs) do
    txs |> Enum.reduce(0, fn x, acc -> length(Map.get(x, "vin", [])) + acc end)
  end

  def vout_count(txs) do
    txs |> Enum.reduce(0, fn x, acc -> length(Map.get(x, "vout", [])) + acc end)
  end

  def is_coinbase_tx?(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    is_coinbase_tx_from_vin(vin)
  end
  
  defp is_coinbase_tx_from_vin([]), do: false
  defp is_coinbase_tx_from_vin(vin) when is_list(vin) do
    first_tx = List.first(vin)
    case Map.fetch(first_tx, "coinbase") do
      {:ok, nil} -> false
      {:ok, _value} -> true
      {:error, _reason} -> false
      :error -> false
    end
  end
  defp is_coinbase_tx_from_vin(_), do: false

  def get_coinbase_hex(tx) do
    tx
    |> Map.get("vin", [])
    |> List.first()
    |> Map.get("coinbase")
    |> decode_coinbase_tx_hex()

    # |> String.normalize(:nfkc)
  end

  def decode_coinbase_tx_hex(coinbase_hex)
      when is_binary(coinbase_hex) do
    try do
      coinbase_binary = Base.decode16!(coinbase_hex, case: :mixed)
      coinbase_list = :erlang.binary_to_list(coinbase_binary)
      List.to_string(coinbase_list) |> IO.inspect(charlists: :as_charlists)
    rescue
      _e in ArgumentError -> "unable to decode coinbase hex"
    end
  end

  def mined_by(txs) do
    first_trx = txs |> List.first()

    if is_coinbase_tx?(first_trx) do
      first_trx
      |> Map.get("vout", [])
      |> List.first()
      |> Map.get("scriptPubKey", %{})
      |> Map.get("addresses", [])
      |> List.first()
    end
  end

  def input_total(txs) when is_list(txs) and length(txs) > 0 do
    txs
    |> Enum.drop(1)  # Skip coinbase transaction
    |> Enum.flat_map(fn x -> Map.get(x, "vin", []) end)
    |> Enum.reduce(0, fn x, acc -> 
      value = Map.get(x, "value", 0) || 0
      acc + value
    end)
    |> Kernel.*(1.0)
    |> Float.to_string()
  end
  def input_total(_), do: "0"

  def output_total(txs) when is_list(txs) do
    txs
    |> Enum.flat_map(fn x -> Map.get(x, "vout", []) end)
    |> Enum.reduce(0, fn x, acc -> 
      value = Map.get(x, "value", 0) || 0
      acc + value
    end)
    |> Kernel.*(1.0)
    |> Float.to_string()
  end
  def output_total(_), do: "0"

  def tx_out_total(tx) when is_map(tx) do
    tx
    |> Map.get("vout", [])
    |> Enum.reduce(0, fn x, acc -> 
      value = Map.get(x, "value", 0) || 0
      acc + value
    end)
    |> Kernel.*(1.0)
    |> Float.to_string()
  end
  def tx_out_total(_), do: "0"

  # detect if a transaction is Public
  # https://z.cash/technology/
  def transparent_in_and_out(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    length(vin) > 0 and length(vout) > 0
  end
  def transparent_in_and_out(_), do: false

  def contains_sprout(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    length(vjoinsplit) > 0
  end
  def contains_sprout(_), do: false

  def contains_orchard(tx) when is_map(tx) do
    TransactionView.orchard_actions(tx) > 0
  end
  def contains_orchard(_), do: false

  def get_joinsplit_count(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    length(vjoinsplit)
  end
  def get_joinsplit_count(_), do: 0

  def contains_sapling(tx) when is_map(tx) do
    value_balance = Map.get(tx, "valueBalance") || 0.0
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    value_balance != 0.0 and (length(vshielded_spend) > 0 or length(vshielded_output) > 0)
  end
  def contains_sapling(_), do: false

  def is_shielded_tx?(tx) when is_map(tx) do
    !transparent_in_and_out(tx) and
      (contains_sprout(tx) or contains_sapling(tx) or contains_orchard(tx))
  end
  def is_shielded_tx?(_), do: false

  def is_transparent_tx?(tx) when is_map(tx) do
    value_balance = Map.get(tx, "valueBalance") || 0.0
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    vjoinsplit = Map.get(tx, "vjoinsplit", [])

    transparent_in_and_out(tx) && length(vjoinsplit) == 0 && value_balance == 0.0 &&
      length(vshielded_spend) == 0 && length(vshielded_output) == 0
  end
  def is_transparent_tx?(_), do: false

  def is_mixed_tx?(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    t_in_or_out = length(vin) > 0 or length(vout) > 0
    t_in_or_out and (contains_sprout(tx) or contains_sapling(tx) or contains_orchard(tx))
  end
  def is_mixed_tx?(_), do: false

  def is_shielding(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    tin_and_zout = length(vin) > 0 and length(vout) == 0
    tin_and_zout and (contains_sprout(tx) or contains_sapling(tx) or contains_orchard(tx))
  end
  def is_shielding(_), do: false

  def is_deshielding(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    zin_and_tout = length(vin) == 0 and length(vout) > 0
    zin_and_tout and (contains_sprout(tx) or contains_sapling(tx) or contains_orchard(tx))
  end
  def is_deshielding(_), do: false

  def tx_type(tx) do
    cond do
      is_coinbase_tx?(tx) ->
        "coinbase"

      is_mixed_tx?(tx) ->
        cond do
          is_shielding(tx) -> "shielding"
          is_deshielding(tx) -> "deshielding"
          true -> "mixed"
        end

      is_shielded_tx?(tx) ->
        "shielded"

      is_transparent_tx?(tx) ->
        "transparent"

      true ->
        "unknown"
    end
  end
end
