defmodule ZclassicExplorerWeb.AddressController do
  use ZclassicExplorerWeb, :controller
  require Logger

  def get_address(conn, %{"address" => address, "s" => s, "e" => e}) do
    if String.starts_with?(address, ["zc", "zs"]) do
      qr =
        address
        |> EQRCode.encode()
        |> EQRCode.png(width: 150, color: <<0, 0, 0>>, background_color: :transparent)
        |> Base.encode64()

      render(conn, "z_address.html",
        address: address,
        qr: qr,
        page_title: "Zclassic Shielded Address"
      )
    end

    {:ok, info} = Cachex.get(:app_cache, "metrics")
    blocks = info["blocks"]

    e = String.to_integer(e)
    s = String.to_integer(s)

    # if requesting for a block that's not yet mined, cap the request to the latest block
    capped_e = if e > blocks, do: blocks, else: e

    balance = case Zclassicex.getaddressbalance([address]) do
      {:ok, b} -> b
      {:error, error} -> 
        Logger.warn("getaddressbalance failed for #{address}: #{inspect(error)}")
        %{}
    end
    
    deltas = case Zclassicex.getaddressdeltas([address]) do
      {:ok, d} -> d
      {:error, error} -> 
        Logger.warn("getaddressdeltas failed for #{address}: #{inspect(error)}")
        %{"deltas" => []}
    end
    
    # If balance is empty, calculate from deltas
    balance = if map_size(balance) == 0 do
      calculate_balance_from_deltas(Map.get(deltas, "deltas", []))
    else
      balance
    end
    
    txs = Map.get(deltas, "deltas", []) |> Enum.reverse()

    qr =
      address
      |> EQRCode.encode()
      |> EQRCode.png(width: 150, color: <<0, 0, 0>>, background_color: :transparent)
      |> Base.encode64()

    render(conn, "address.html",
      address: address,
      balance: balance,
      txs: txs,
      qr: qr,
      end_block: e,
      start_block: s,
      latest_block: blocks,
      capped_e: capped_e,
      page_title: "Zclassic Address #{address}"
    )
  end

  def get_address(conn, %{"address" => address}) do
    if String.starts_with?(address, ["zc", "zs"]) do
      qr =
        address
        |> EQRCode.encode()
        |> EQRCode.png(width: 150, color: <<0, 0, 0>>, background_color: :transparent)
        |> Base.encode64()

      render(conn, "z_address.html",
        address: address,
        qr: qr,
        page_title: "Zclassic Shielded Address"
      )
    end

    c = 128
    {:ok, info} = Cachex.get(:app_cache, "metrics")
    latest_block = info["blocks"]
    e = latest_block
    s = ((c - 1) * (e / c)) |> floor()
    s = if s <= 0, do: 1, else: s
    
    # Gestisci correttamente le risposte RPC
    balance = case Zclassicex.getaddressbalance([address]) do
      {:ok, b} -> b
      {:error, error} -> 
        Logger.warn("getaddressbalance failed for #{address}: #{inspect(error)}")
        %{}
    end
    
    deltas = case Zclassicex.getaddressdeltas([address]) do
      {:ok, d} -> d
      {:error, error} -> 
        Logger.warn("getaddressdeltas failed for #{address}: #{inspect(error)}")
        %{"deltas" => []}
    end
    
    # If balance is empty, calculate from deltas
    balance = if map_size(balance) == 0 do
      calculate_balance_from_deltas(Map.get(deltas, "deltas", []))
    else
      balance
    end
    
    txs = Map.get(deltas, "deltas", []) |> Enum.reverse()

    qr =
      address
      |> EQRCode.encode()
      |> EQRCode.png(width: 150, color: <<0, 0, 0>>, background_color: :transparent)
      |> Base.encode64()

    render(conn, "address.html",
      address: address,
      balance: balance,
      txs: txs,
      qr: qr,
      end_block: e,
      start_block: s,
      latest_block: latest_block,
      capped_e: nil,
      page_title: "Zclassic Address #{address}"
    )
  end

  def get_ua(conn, %{"address" => ua}) do
    {:ok, details} = Zclassicex.z_listunifiedreceivers(ua)
    IO.inspect(details)
    orchard_present = Map.has_key?(details, "orchard")
    transparent_present = Map.has_key?(details, "p2pkh")
    sapling_present = Map.has_key?(details, "sapling")

    if String.starts_with?(ua, ["u"]) do
      u_qr =
        ua
        |> EQRCode.encode()
        |> EQRCode.png(width: 150, color: <<0, 0, 0>>, background_color: :transparent)
        |> Base.encode64()

      render(conn, "u_address.html",
        address: ua,
        qr: u_qr,
        page_title: "Zclassic Unified Address",
        orchard_present: orchard_present,
        transparent_present: transparent_present,
        sapling_present: sapling_present,
        details: details
      )
    end
  end

  # Helper function to calculate balance from deltas when getaddressbalance is not available
  defp calculate_balance_from_deltas(deltas) when is_list(deltas) do
    deltas
    |> Enum.reduce(%{"balance" => 0, "received" => 0}, fn delta, acc ->
      amount = Map.get(delta, "amount", 0)
      satoshis = Map.get(delta, "satoshis", 0)
      
      received = acc["received"] + abs(satoshis)
      balance = if satoshis > 0, do: acc["balance"] + satoshis, else: acc["balance"] + satoshis
      
      %{"balance" => balance, "received" => received}
    end)
  end

  defp calculate_balance_from_deltas(_), do: %{"balance" => 0, "received" => 0}
end
