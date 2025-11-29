defmodule Zclassicex do
  @moduledoc """
  Zclassic RPC Client for communicating with zclassicd node.
  
  This module provides a GenServer-based client for making JSON-RPC calls
  to a Zclassic daemon (zclassicd).
  """

  use GenServer
  require Logger

  @type rpc_error :: {:error, term()}
  @type rpc_success :: {:ok, term()}

  # Client API

  @doc """
  Starts the Zclassicex GenServer.
  
  ## Parameters
  
    - hostname: Hostname of the zclassicd node (default: "localhost")
    - port: RPC port (default: 8023)
    - username: RPC username
    - password: RPC password
  """
  def start_link(hostname, port, username, password) do
    GenServer.start_link(__MODULE__, %{
      hostname: hostname,
      port: port,
      username: username,
      password: password
    }, name: __MODULE__)
  end

  @doc """
  Makes a JSON-RPC call to the Zclassic node.
  
  ## Parameters
  
    - method: The RPC method name (e.g., "getinfo", "getblockchaininfo")
    - params: List of parameters for the RPC method (default: [])
  
  ## Examples
  
      iex> Zclassicex.call("getinfo")
      {:ok, %{"version" => 1000000, ...}}
      
      iex> Zclassicex.call("getblock", ["00000000..."])
      {:ok, %{"hash" => "00000000...", ...}}
  """
  def call(method, params \\ []) do
    GenServer.call(__MODULE__, {:rpc_call, method, params}, 30_000)
  end

  # Server Callbacks

  @impl true
  def init(state) do
    Logger.info("Zclassicex RPC client started - connecting to #{state.hostname}:#{state.port}")
    {:ok, state}
  end

  @impl true
  def handle_call({:rpc_call, method, params}, _from, state) do
    result = make_rpc_request(method, params, state)
    {:reply, result, state}
  end

  # Private Functions

  defp make_rpc_request(method, params, state) do
    url = "http://#{state.hostname}:#{state.port}/"
    
    body = Jason.encode!(%{
      jsonrpc: "1.0",
      id: "zclassic_explorer",
      method: method,
      params: params
    })

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Basic " <> Base.encode64("#{state.username}:#{state.password}")}
    ]

    options = [
      recv_timeout: 30_000,
      timeout: 30_000
    ]

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"result" => result, "error" => nil}} ->
            {:ok, result}
          
          {:ok, %{"error" => error}} when not is_nil(error) ->
            Logger.error("RPC Error: #{inspect(error)}")
            {:error, error}
          
          {:error, decode_error} ->
            Logger.error("JSON Decode Error: #{inspect(decode_error)}")
            {:error, :decode_error}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("HTTP Error #{status_code}: #{body}")
        {:error, {:http_error, status_code, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Connection Error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  rescue
    e ->
      Logger.error("Unexpected error in RPC call: #{inspect(e)}")
      {:error, {:exception, e}}
  end

  # Convenience Functions for Common RPC Calls

  @doc "Get general information about the Zclassic node"
  def getinfo, do: call("getinfo")

  @doc "Get blockchain information"
  def getblockchaininfo, do: call("getblockchaininfo")

  @doc "Get the current block count"
  def getblockcount, do: call("getblockcount")

  @doc "Get block hash by height"
  def getblockhash(height), do: call("getblockhash", [height])

  @doc "Get block by hash"
  def getblock(hash, verbosity \\ 1), do: call("getblock", [hash, verbosity])

  @doc "Get raw transaction"
  def getrawtransaction(txid, verbose \\ 1), do: call("getrawtransaction", [txid, verbose])

  @doc "Get mempool info"
  def getmempoolinfo, do: call("getmempoolinfo")

  @doc "Get raw mempool"
  def getrawmempool(verbose \\ false), do: call("getrawmempool", [verbose])

  @doc "Get network info"
  def getnetworkinfo, do: call("getnetworkinfo")

  @doc "Get peer info"
  def getpeerinfo, do: call("getpeerinfo")

  @doc "Get mining info"
  def getmininginfo, do: call("getmininginfo")

  @doc "Get difficulty"
  def getdifficulty, do: call("getdifficulty")

  @doc "Get connection count"
  def getconnectioncount, do: call("getconnectioncount")

  @doc "Get network hash rate"
  def getnetworkhashps(blocks \\ 120, height \\ -1), do: call("getnetworkhashps", [blocks, height])

  @doc "Get network sol/s (for Equihash)"
  def getnetworksolps(blocks \\ 120, height \\ -1), do: call("getnetworksolps", [blocks, height])

  @doc "Decode raw transaction"
  def decoderawtransaction(hex), do: call("decoderawtransaction", [hex])

  @doc "Get transaction output info"
  def gettxout(txid, n, include_mempool \\ true), do: call("gettxout", [txid, n, include_mempool])

  @doc "Get best block hash"
  def getbestblockhash, do: call("getbestblockhash")

  @doc "Validate address"
  def validateaddress(address), do: call("validateaddress", [address])

  @doc "Get address balance"
  def getaddressbalance(addresses), do: call("getaddressbalance", [%{"addresses" => addresses}])

  @doc "Get address deltas"
  def getaddressdeltas(addresses), do: call("getaddressdeltas", [%{"addresses" => addresses}])

  @doc "Get address txids"
  def getaddresstxids(addresses), do: call("getaddresstxids", [%{"addresses" => addresses}])

  @doc "Get address utxos"
  def getaddressutxos(addresses), do: call("getaddressutxos", [%{"addresses" => addresses}])

  @doc "Get address mempool"
  def getaddressmempool(addresses), do: call("getaddressmempool", [%{"addresses" => addresses}])

  @doc "Get block deltas"
  def getblockdeltas(hash), do: call("getblockdeltas", [hash])

  @doc "Get blockchain size"
  def getchaintxstats(nblocks \\ nil, blockhash \\ nil) do
    params = [nblocks, blockhash] |> Enum.reject(&is_nil/1)
    call("getchaintxstats", params)
  end

  @doc "Get z address balance"
  def z_getbalance(address, minconf \\ 1), do: call("z_getbalance", [address, minconf])

  @doc "List z addresses"
  def z_listaddresses, do: call("z_listaddresses")

  @doc "Get total balance"
  def z_gettotalbalance(minconf \\ 1), do: call("z_gettotalbalance", [minconf])
end
