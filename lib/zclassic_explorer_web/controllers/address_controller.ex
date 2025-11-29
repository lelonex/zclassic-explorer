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

    # Use blockchain scanner to find transactions (limited scan for speed)
    {txs, balance} = ZclassicExplorer.BlockchainScanner.get_address_transactions(address, 20)
    txs = Enum.reverse(txs)

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
    
    # Use blockchain scanner to find transactions (limited scan for speed)
    {txs, balance} = ZclassicExplorer.BlockchainScanner.get_address_transactions(address, 20)
    txs = Enum.reverse(txs)

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
end
