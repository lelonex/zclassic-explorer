defmodule ZclassicExplorerWeb.PageController do
  use ZclassicExplorerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Zclassic Explorer - Search the Zcash Blockchain")
  end

  def broadcast(conn, _params) do
    render(conn, "broadcast.html",
      csrf_token: get_csrf_token(),
      page_title: "Broadcast raw Zcash transaction"
    )
  end

  def do_broadcast(conn, params) do
    tx_hex = params["tx-hex"]

    case Zclassicex.sendrawtransaction(tx_hex) do
      {:ok, resp} ->
        conn
        |> put_flash(:info, resp)
        |> render("broadcast.html",
          csrf_token: get_csrf_token(),
          page_title: "Broadcast raw Zcash transaction"
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> render("broadcast.html",
          csrf_token: get_csrf_token(),
          page_title: "Broadcast raw Zcash Transaction"
        )
    end
  end

  def disclosure(conn, _params) do
    render(conn, "disclosure.html",
      csrf_token: get_csrf_token(),
      disclosed_data: nil,
      disclosure_hex: nil,
      page_title: "Zclassic Payment Disclosure"
    )
  end

  def do_disclosure(conn, params) do
    disclosure_hex = String.trim(params["disclosure-hex"])

    case Zclassicex.z_validatepaymentdisclosure(disclosure_hex) do
      {:ok, resp} ->
        conn
        |> put_flash(:info, resp)
        |> render("disclosure.html",
          csrf_token: get_csrf_token(),
          disclosed_data: resp,
          disclosure_hex: disclosure_hex,
          page_title: "Zclassic Payment Disclosure"
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> render("disclosure.html",
          csrf_token: get_csrf_token(),
          disclosed_data: nil,
          disclosure_hex: disclosure_hex,
          page_title: "Zclassic Payment Disclosure"
        )
    end
  end

  def mempool(conn, _params) do
    render(conn, "mempool.html", page_title: "Zclassic Mempool")
  end

  def nodes(conn, _params) do
    render(conn, "nodes.html", page_title: "Zclassic Nodes")
  end

  def vk(conn, _params) do
    height =
      case Cachex.get(:app_cache, "metrics") do
        {:ok, info} ->
          info["blocks"] - 10000

        {:error, _reason} ->
          # hardcoded to canopy
          1_046_400
      end

    render(conn, "vk.html",
      csrf_token: get_csrf_token(),
      height: height,
      page_title: "Zclassic Viewing Key"
    )
  end

  def do_import_vk(conn, params) do
    height = params["scan-height"]
    vkey = params["vkey"]
    cur_jobs = Cachex.get!(:app_cache, "nbjobs") || 1

    with true <- String.starts_with?(vkey, "zxview"),
         true <- is_integer(String.to_integer(height)),
         true <- String.to_integer(height) >= 0,
         true <- cur_jobs <= 10 do
      cmd =
        MuonTrap.cmd("docker", [
          "create",
          "-t",
          "-i",
          "--rm",
          "--ulimit",
          "nofile=90000:90000",
          "--cpus",
          Application.get_env(:zclassic_explorer, Zclassicex)[:vk_cpus],
          "-m",
          Application.get_env(:zclassic_explorer, Zclassicex)[:vk_mem],
          Application.get_env(:zclassic_explorer, Zclassicex)[:vk_runnner_image],
          "zecwallet-cli",
          "import",
          vkey,
          height
        ])

      container_id = elem(cmd, 0) |> String.trim_trailing("\n") |> String.slice(0, 12)
      Task.start(fn -> MuonTrap.cmd("docker", ["start", "-a", "-i", container_id]) end)

      render(conn, "vk_txs.html",
        csrf_token: get_csrf_token(),
        height: height,
        container_id: container_id,
        page_title: "Zclassic Viewing Key"
      )
    else
      false ->
        conn
        |> put_flash(:error, "Invalid Input")
        |> render("vk.html",
          csrf_token: get_csrf_token(),
          height: height,
          page_title: "Zclassic Viewing Key"
        )
    end
  end

  def vk_from_zecwalletcli(conn, params) do
    container_id = Map.get(params, "hostname")
    chan = "VK:" <> "#{container_id}"
    txs = Map.get(params, "_json")
    Phoenix.PubSub.broadcast(ZclassicExplorer.PubSub, chan, {:received_txs, txs})
    json(conn, %{status: "received"})
  end

  def blockchain_info(conn, _params) do
    render(conn, "blockchain_info.html", page_title: "Zclassic Blockchain Info")
  end

  def blockchain_info_api(conn, _params) do
    {:ok, info} = Cachex.get(:app_cache, "metrics")
    {:ok, %{"build" => build}} = Cachex.get(:app_cache, "info")
    info = Map.put(info, "build", build)
    json(conn, info)
  end

  def statistics(conn, _params) do
    blockchain_info = case Cachex.get(:app_cache, "metrics") do
      {:ok, info} -> info
      _ -> nil
    end
    
    stats_data = case Cachex.get(:app_cache, "statistics_data") do
      {:ok, data} -> data
      _ -> %{latest: %{}, history: [], charts: %{}}
    end
    
    render(conn, "statistics.html", 
      blockchain_info: blockchain_info,
      stats_data: stats_data,
      page_title: "Zclassic Network Statistics"
    )
  end

  def rich_list(conn, _params) do
    # Get rich list from cache
    rich_list = case Cachex.get(:app_cache, "rich_list_data") do
      {:ok, list} when is_list(list) -> list
      _ -> []
    end
    
    total_supply = case Cachex.get(:app_cache, "metrics") do
      {:ok, info} -> info["moneysupply"] || 11_462_487
      _ -> 11_462_487
    end

    render(conn, "rich_list.html",
      rich_list: rich_list,
      total_supply: total_supply,
      page_title: "Zclassic Rich List - Top Addresses"
    )
  end

  def status(conn, _params) do
    blockchain_info = case Cachex.get(:app_cache, "metrics") do
      {:ok, info} -> info
      _ -> nil
    end
    
    node_info = case Zclassicex.getinfo() do
      {:ok, info} -> info
      _ -> nil
    end

    render(conn, "status.html",
      blockchain_info: blockchain_info,
      node_info: node_info,
      page_title: "Zclassic Application Status"
    )
  end

  def market(conn, _params) do
    render(conn, "market.html", page_title: "Zclassic Market Analysis")
  end

end
