defmodule ZclassicExplorerWeb.TransactionView do
  use ZclassicExplorerWeb, :view

  def zcash_network do
    Application.get_env(:zclassic_explorer, Zclassicex)[:zcash_network] || "mainnet"
  end

  def vin_vout_count(tx) when is_map(tx) do
    vin_count = length(Map.get(tx, "vin", []))
    vout_count = length(Map.get(tx, "vout", []))
    "#{vin_count} / #{vout_count}"
  end
  def vin_vout_count(_), do: "0 / 0"

  def vin_count(vin) do
    length(vin)
  end

  def vout_count(vout) do
    length(vout)
  end

  def format_zec(value) when value == nil do
    ""
  end

  def format_zec(value) when value != nil do
    zcash_network = Application.get_env(:zclassic_explorer, Zclassicex)[:zcash_network]
    currency = "ZCL"
    float_value = (value + 0.0) |> :erlang.float_to_binary([:compact, {:decimals, 10}])
    float_value <> " " <> currency
  end

  def orchard_actions(tx) do
    case tx do
      %{orchard: %{actions: actions}} when is_list(actions) -> length(actions)
      _ -> 0
    end
  end

  def get_shielded_pool_label(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    value_balance = Map.get(tx, "valueBalance", 0)
    version = Map.get(tx, "version", 0)
    orchard = Map.get(tx, "orchard", %{})
    orchard_actions = Map.get(orchard, "actions", nil)
    orchard_value_balance = Map.get(orchard, "valueBalance", 0)

    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    vin_len = if is_list(vin), do: length(vin), else: 0
    vout_len = if is_list(vout), do: length(vout), else: 0
    vshielded_output_len = if is_list(vshielded_output), do: length(vshielded_output), else: 0
    vshielded_spend_len = if is_list(vshielded_spend), do: length(vshielded_spend), else: 0
    orchard_actions_len = if is_list(orchard_actions), do: length(orchard_actions), else: 0

    cond do
      # Version 5 orchard case with positive balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 and version == 5 and
        orchard_actions_len > 0 and orchard_value_balance > 0 ->
        "Transferred from shielded pool"

      # Version 5 orchard case with negative balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 and version == 5 and
        orchard_actions_len > 0 and orchard_value_balance < 0 ->
        "Transferred to shielded pool"

      # Shielded output without spend
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len > 0 and vshielded_spend_len == 0 and
        value_balance < 0.0 and version == 5 ->
        "Transferred from/to shielded pool"

      # Shielded with positive vout
      vjoinsplit_len == 0 and vin_len == 0 and vout_len > 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "Transferred from shielded pool"

      # Both spend and output zero
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "Transferred from/to shielded pool"

      # Both output and spend present
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len > 0 and vshielded_spend_len > 0 and
        value_balance == 0.0 ->
        "Transferred from/to shielded pool"

      # Mixed tx with positive vin and output but negative value
      vjoinsplit_len == 0 and vin_len > 0 and vout_len == 0 and
        vshielded_output_len > 0 and value_balance < 0.0 ->
        "Transferred to shielded pool"

      # Legacy vjoinsplit with vin
      vjoinsplit_len > 0 and vin_len > 0 ->
        "Transferred to shielded pool"

      # Legacy vjoinsplit without vin
      vjoinsplit_len > 0 and vin_len == 0 ->
        "Transferred from shielded pool"

      # Mixed tx with vin and shielded output
      vjoinsplit_len == 0 and vin_len > 0 and vshielded_output_len > 0 and
        value_balance < 0.0 ->
        "Transferred to shielded pool"

      # Public tx with vin
      vjoinsplit_len == 0 and vin_len > 0 ->
        "Transferred from/to shielded pool"

      # Positive vout with positive value balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len > 0 and
        value_balance > 0 ->
        "Transferred from shielded pool"

      # Zero vout with positive value balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        value_balance > 0 ->
        "Transferred from shielded pool"

      true ->
        "Unknown"
    end
  end


  # Consolidated shielded pool value calculation
  def get_shielded_pool_value(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    value_balance = Map.get(tx, "valueBalance", 0)
    version = Map.get(tx, "version", 0)
    orchard = Map.get(tx, "orchard", %{})
    orchard_actions = Map.get(orchard, "actions", nil)
    orchard_value_balance = Map.get(orchard, "valueBalance", 0)

    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    vin_len = if is_list(vin), do: length(vin), else: 0
    vout_len = if is_list(vout), do: length(vout), else: 0
    vshielded_output_len = if is_list(vshielded_output), do: length(vshielded_output), else: 0
    vshielded_spend_len = if is_list(vshielded_spend), do: length(vshielded_spend), else: 0
    orchard_actions_len = if is_list(orchard_actions), do: length(orchard_actions), else: 0

    cond do
      # Version 5 orchard case
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 and version == 5 and
        orchard_actions_len > 0 ->
        orchard_value_balance

      # Shielded output without spend and negative value
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len > 0 and vshielded_spend_len == 0 and
        value_balance < 0.0 and version == 5 ->
        0

      # Shielded with positive vout
      vjoinsplit_len == 0 and vin_len == 0 and vout_len > 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        vjoinsplit |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_old", 0) + acc end)

      # Both output and spend present
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len > 0 and vshielded_spend_len > 0 and
        value_balance == 0.0 ->
        0.0

      # Mixed tx with positive vin and output but negative value
      vjoinsplit_len == 0 and vin_len > 0 and vshielded_output_len > 0 and
        value_balance < 0.0 ->
        abs(value_balance)

      # Mixed tx with vin, vout and output but negative value (alternate case)
      vjoinsplit_len == 0 and vin_len > 0 and vout_len == 0 and
        vshielded_output_len > 0 and value_balance < 0.0 ->
        abs(value_balance)

      # Legacy vjoinsplit with vin
      vjoinsplit_len > 0 and vin_len > 0 ->
        vjoinsplit |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_old", 0) + acc end)

      # Legacy vjoinsplit without vin but with no vout
      vjoinsplit_len > 0 and vin_len == 0 and vout_len == 0 ->
        val =
          vjoinsplit
          |> List.flatten()
          |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_new", 0) + acc end)
          |> Kernel.+(0.0)

        abs(val)

      # Legacy vjoinsplit without vin with vout
      vjoinsplit_len > 0 and vin_len == 0 and vout_len > 0 ->
        val =
          vjoinsplit
          |> List.flatten()
          |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_new", 0) + acc end)
          |> Kernel.+(0.0)

        abs(val)

      # Zero vout with positive value balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        value_balance > 0 ->
        abs(value_balance)

      # Public tx with vin
      vjoinsplit_len == 0 and vin_len > 0 ->
        0.00

      # Positive vout with positive value balance
      vjoinsplit_len == 0 and vin_len == 0 and vout_len > 0 and
        value_balance > 0 ->
        abs(value_balance)

      true ->
        0
    end
  end


  def tx_in_total(tx) when is_map(tx) do
    vin = Map.get(tx, "vin", [])
    vin |> Enum.reduce(0, fn x, acc -> Map.get(x, "value", 0) + acc end)
  end

  def tx_out_total(tx) when is_map(tx) do
    vout = Map.get(tx, "vout", [])
    vout |> Enum.reduce(0, fn x, acc -> Map.get(x, "value", 0) + acc end)
  end

  def transparent_tx_fee(public_tx) do
    fee = tx_in_total(public_tx) - tx_out_total(public_tx)
    fee |> format_zec()
  end

  def vjoinsplit_vpub_old_total(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vjoinsplit |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_old", 0) + acc end)
  end

  def vjoinsplit_vpub_new_total(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vjoinsplit |> Enum.reduce(0, fn x, acc -> Map.get(x, "vpub_new", 0) + acc end)
  end

  def shielding_tx_fee(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    version = Map.get(tx, "version", 0)
    value_balance = Map.get(tx, "valueBalance", 0)
    orchard = Map.get(tx, "orchard", %{})
    orchard_value_balance = Map.get(orchard, "valueBalance", 0)
    
    cond do
      vjoinsplit_len > 0 ->
        fee = tx_in_total(tx) - vjoinsplit_vpub_old_total(tx)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version <= 4 ->
        fee = tx_in_total(tx) - abs(value_balance)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version == 5 and orchard_value_balance == 0 ->
        fee = tx_in_total(tx) - abs(value_balance)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version == 5 ->
        fee = tx_in_total(tx) - abs(orchard_value_balance)
        fee |> format_zec()
      
      true ->
        "N/A"
    end
  end

  def deshielding_tx_fees(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    version = Map.get(tx, "version", 0)
    value_balance = Map.get(tx, "valueBalance", 0)
    orchard = Map.get(tx, "orchard", %{})
    orchard_value_balance = Map.get(orchard, "valueBalance", 0)
    
    cond do
      vjoinsplit_len > 0 ->
        fee = vjoinsplit_vpub_new_total(tx) - tx_out_total(tx)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version <= 4 ->
        fee = value_balance - tx_out_total(tx)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version == 5 and orchard_value_balance == 0 ->
        fee = value_balance - tx_out_total(tx)
        fee |> format_zec()
      
      vjoinsplit_len == 0 and version == 5 ->
        fee = orchard_value_balance - tx_out_total(tx)
        fee |> format_zec()
      
      true ->
        "N/A"
    end
  end

  def deshielding_tx_fees(_), do: "N/A"

  #
  def deshielding_tx_fees_old(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    version = Map.get(tx, "version", 0)
    value_balance = Map.get(tx, "valueBalance", 0)
    orchard = Map.get(tx, "orchard", %{})
    orchard_value_balance = Map.get(orchard, "valueBalance", 0)

    cond do
      vjoinsplit_len > 0 ->
        fee = vjoinsplit_vpub_new_total(tx) - tx_out_total(tx)
        fee |> format_zec()

      vjoinsplit_len == 0 and version <= 4 ->
        fee = value_balance - tx_out_total(tx)
        fee |> format_zec()

      vjoinsplit_len == 0 and version == 5 and orchard_value_balance == 0 ->
        fee = value_balance - tx_out_total(tx)
        fee |> format_zec()

      vjoinsplit_len == 0 and version == 5 ->
        fee = orchard_value_balance - tx_out_total(tx)
        fee |> format_zec()

      true ->
        "N/A"
    end
  end

  def unknown_tx_fees(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    value_balance = Map.get(tx, "valueBalance", 0)
    version = Map.get(tx, "version", 0)

    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    vin_len = if is_list(vin), do: length(vin), else: 0
    vout_len = if is_list(vout), do: length(vout), else: 0
    vshielded_output_len = if is_list(vshielded_output), do: length(vshielded_output), else: 0
    vshielded_spend_len = if is_list(vshielded_spend), do: length(vshielded_spend), else: 0

    cond do
      version == 5 and vjoinsplit_len == 0 and vin_len > 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "¯\\_(ツ)_/¯"

      version == 5 and vjoinsplit_len == 0 and vin_len > 0 and vout_len > 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance < 0.0 ->
        "¯\\_(ツ)_/¯"

      version == 5 and vjoinsplit_len == 0 and vin_len > 0 and vout_len > 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "¯\\_(ツ)_/¯"

      version == 5 and vjoinsplit_len == 0 and vin_len == 0 and vout_len > 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "¯\\_(ツ)_/¯"

      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len == 0 and vshielded_spend_len == 0 and
        value_balance == 0.0 ->
        "¯\\_(ツ)_/¯"

      vjoinsplit_len == 0 and vin_len == 0 and vout_len == 0 and
        vshielded_output_len > 0 and vshielded_spend_len > 0 and
        value_balance == 0.0 ->
        fee = 0.0
        fee |> format_zec()

      true ->
        "N/A"
    end
  end

  def mixed_tx_fees(tx) when is_map(tx) do
    vjoinsplit = Map.get(tx, "vjoinsplit", [])
    vshielded_output = Map.get(tx, "vShieldedOutput", [])
    vshielded_spend = Map.get(tx, "vShieldedSpend", [])
    value_balance = Map.get(tx, "valueBalance", 0)
    vin = Map.get(tx, "vin", [])
    vout = Map.get(tx, "vout", [])

    vjoinsplit_len = if is_list(vjoinsplit), do: length(vjoinsplit), else: 0
    vshielded_output_len = if is_list(vshielded_output), do: length(vshielded_output), else: 0
    vshielded_spend_len = if is_list(vshielded_spend), do: length(vshielded_spend), else: 0
    vin_len = if is_list(vin), do: length(vin), else: 0
    vout_len = if is_list(vout), do: length(vout), else: 0

    cond do
      vjoinsplit_len == 0 and vshielded_output_len > 0 and vshielded_spend_len > 0 and
        value_balance > 0 and vin_len > 0 and vout_len > 0 ->
        fee = tx_in_total(tx) - tx_out_total(tx) + value_balance
        fee |> format_zec()

      vjoinsplit_len == 0 and vshielded_output_len > 0 and vshielded_spend_len == 0 and
        value_balance < 0 and vin_len > 0 and vout_len > 0 ->
        fee = tx_in_total(tx) - abs(value_balance) - tx_out_total(tx)
        fee |> format_zec()

      vjoinsplit_len == 0 and vshielded_output_len > 0 and vshielded_spend_len > 0 and
        value_balance < 0 and vin_len > 0 and vout_len > 0 ->
        fee = tx_in_total(tx) - abs(value_balance) - tx_out_total(tx)
        fee |> format_zec()

      true ->
        "N/A"
    end
  end

  # Catch-all for get_shielded_pool_label with map data
  def get_shielded_pool_label(_tx), do: ""

  # Catch-all for get_shielded_pool_value with map data
  def get_shielded_pool_value(_tx), do: 0
end
