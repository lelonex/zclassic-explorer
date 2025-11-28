defmodule ZclassicExplorer.Price.PriceFetcher do
  use GenServer
  require Logger

  @update_interval 300_000 # 5 minutes
  @coingecko_url "https://api.coingecko.com/api/v3"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    # Fetch price immediately on start
    schedule_update(1000)
    {:ok, state}
  end

  def get_price do
    case Cachex.get(:app_cache, "zcl_price") do
      {:ok, price} when not is_nil(price) -> {:ok, price}
      _ -> {:error, :not_available}
    end
  end

  def handle_info(:update_price, state) do
    fetch_and_cache_price()
    schedule_update(@update_interval)
    {:noreply, state}
  end

  defp schedule_update(interval) do
    Process.send_after(self(), :update_price, interval)
  end

  defp fetch_and_cache_price do
    try do
      # Fetch ZCL price from CoinGecko
      coin_url = "#{@coingecko_url}/coins/zclassic"
      
      case HTTPoison.get(coin_url, [], timeout: 10_000, recv_timeout: 10_000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} ->
              price_data = %{
                usd: get_in(data, ["market_data", "current_price", "usd"]) || 0,
                btc: get_in(data, ["market_data", "current_price", "btc"]) || 0,
                usd_24h_change: get_in(data, ["market_data", "price_change_percentage_24h"]) || 0,
                market_cap_usd: get_in(data, ["market_data", "market_cap", "usd"]) || 0,
                total_volume_usd: get_in(data, ["market_data", "total_volume", "usd"]) || 0,
                circulating_supply: get_in(data, ["market_data", "circulating_supply"]) || 0,
                last_updated: DateTime.utc_now() |> DateTime.to_iso8601()
              }
              
              # Fetch market data
              markets_data = fetch_markets()
              price_data = Map.put(price_data, :markets, markets_data)
              
              Cachex.put(:app_cache, "zcl_price", price_data)
              Logger.info("Price updated: $#{price_data.usd} USD, #{price_data.btc} BTC")
              {:ok, price_data}

            {:error, reason} ->
              Logger.error("Failed to decode CoinGecko response: #{inspect(reason)}")
              {:error, reason}
          end

        {:ok, %HTTPoison.Response{status_code: status_code}} ->
          Logger.error("CoinGecko API returned status #{status_code}")
          {:error, :api_error}

        {:error, reason} ->
          Logger.error("Failed to fetch from CoinGecko: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exception fetching price: #{inspect(e)}")
        {:error, :exception}
    end
  end

  defp fetch_markets do
    markets_url = "#{@coingecko_url}/coins/zclassic/tickers"
    
    case HTTPoison.get(markets_url, [], timeout: 10_000, recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"tickers" => tickers}} ->
            tickers
            |> Enum.take(10) # Top 10 markets
            |> Enum.map(fn ticker ->
              %{
                exchange: ticker["market"]["name"],
                pair: "#{ticker["base"]}/#{ticker["target"]}",
                price: ticker["last"],
                volume_24h: ticker["volume"],
                trust_score: ticker["trust_score"],
                url: ticker["trade_url"]
              }
            end)

          _ -> []
        end

      _ -> []
    end
  end
end
