defmodule ZclassicExplorerWeb.TransactionController do
  use ZclassicExplorerWeb, :controller

  def get_transaction(conn, %{"txid" => txid}) do
    case Zclassicex.getrawtransaction(txid, 1) do
      {:ok, tx} when is_map(tx) ->
        # tx is already a map from RPC, no need for struct conversion
        render(conn, "tx.html", tx: tx, page_title: "Zclassic Transaction #{txid}")

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> put_view(ZclassicExplorerWeb.ErrorView)
        |> render(:not_found)
    end
  end

  def get_raw_transaction(conn, %{"txid" => txid}) do
    {:ok, tx} = Zclassicex.getrawtransaction(txid, 1)
    data = Poison.encode!(tx, pretty: true)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data)
  end
end
