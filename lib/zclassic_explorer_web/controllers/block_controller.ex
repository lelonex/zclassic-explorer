defmodule ZclassicExplorerWeb.BlockController do
  use ZclassicExplorerWeb, :controller

  def get_block(conn, %{"hash" => hash}) do
    case Zclassicex.getblock(hash, 1) do
      {:ok, basic_block_data} ->
        case length(Map.get(basic_block_data, "tx", [])) do
          0 ->
            conn
            |> put_status(:not_found)
            |> put_view(ZclassicExplorerWeb.ErrorView)
            |> render(:not_found)

          n when n <= 250 ->
            case Zclassicex.getblock(hash, 2) do
              {:ok, block_data} ->
                height = Map.get(block_data, "height")

                render(conn, "index.html",
                  block_data: block_data,
                  block_subsidy: nil,
                  page_title: "Zclassic block #{height}"
                )

              {:error, _} ->
                conn
                |> put_status(:not_found)
                |> put_view(ZclassicExplorerWeb.ErrorView)
                |> render(:not_found)
            end

          n when n > 250 ->
            render(conn, "basic_block.html",
              block_data: basic_block_data,
              page_title: "Zclassic block #{hash}"
            )
        end

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> put_view(ZclassicExplorerWeb.ErrorView)
        |> render(:not_found)
    end
  end

  def by_date(conn, %{"date" => date}) do
    now = NaiveDateTime.utc_now() |> Timex.beginning_of_day()
    parsed_date = Timex.parse!(date, "{YYYY}-{0M}-{D}")
    diff = Timex.diff(parsed_date, now, :day)

    if diff > 0 do
      conn
      |> put_status(:not_found)
      |> put_view(ZclassicExplorerWeb.ErrorView)
      |> render(:invalid_input)
    end

    previous = Timex.shift(parsed_date, days: -1) |> Timex.format!("{YYYY}-{0M}-{D}")
    next = Timex.shift(parsed_date, days: 1) |> Timex.format!("{YYYY}-{0M}-{D}")
    first_block_date = "2016-10-28"
    disable_previous = if first_block_date == date, do: true, else: false

    disable_next =
      if Timex.today() |> Timex.format!("{YYYY}-{0M}-{D}") == date, do: true, else: false

    # Get blocks by scanning from current height and filtering by date
    high = parsed_date |> Timex.end_of_day() |> Timex.to_unix()
    low = parsed_date |> Timex.beginning_of_day() |> Timex.to_unix()

    blocks_data = get_blocks_by_date_range(low, high)

    render(
      conn,
      "blocks.html",
      blocks_data: blocks_data,
      date: date,
      disable_next: disable_next,
      disable_previous: disable_previous,
      next: next,
      previous: previous,
      page_title: "Zclassic blocks mined on #{date}"
    )
  end

  defp get_blocks_by_date_range(low_ts, high_ts) do
    case Zclassicex.getblockcount() do
      {:ok, height} when is_integer(height) ->
        # Scan backwards to find blocks in date range, with no max limit
        scan_blocks_in_range(height, low_ts, high_ts, [])
      _ -> []
    end
  end

  defp scan_blocks_in_range(height, _low_ts, _high_ts, acc) when height < 1, do: Enum.reverse(acc)
  defp scan_blocks_in_range(height, low_ts, high_ts, acc) do
    case Zclassicex.getblockhash(height) do
      {:ok, hash} ->
        case Zclassicex.getblock(hash, 1) do
          {:ok, block} ->
            block_time = Map.get(block, "time", 0)
            cond do
              block_time > high_ts ->
                # Block is after range, keep scanning backwards
                scan_blocks_in_range(height - 1, low_ts, high_ts, acc)
              block_time >= low_ts and block_time <= high_ts ->
                # Block is in range, add it
                scan_blocks_in_range(height - 1, low_ts, high_ts, [block | acc])
              block_time < low_ts ->
                # Block is before range, stop scanning
                Enum.reverse(acc)
              true ->
                scan_blocks_in_range(height - 1, low_ts, high_ts, acc)
            end
          _ ->
            scan_blocks_in_range(height - 1, low_ts, high_ts, acc)
        end
      _ ->
        scan_blocks_in_range(height - 1, low_ts, high_ts, acc)
    end
  end

  def index(conn, %{"date" => date}) do
    by_date(conn, %{"date" => date})
  end

  def index(conn, _params) do
    today = Timex.today()
    today_str = today |> Timex.format!("{YYYY}-{0M}-{D}")
    disable_next = true
    disable_previous = false
    previous = Timex.shift(today, days: -1) |> Timex.format!("{YYYY}-{0M}-{D}")

    # Usa getblockcount + getblockhash invece di getblockhashes
    case Zclassicex.getblockcount() do
      {:ok, height} when is_integer(height) ->
        blocks_data =
          for h <- height..(max(height - 49, 1)), h > 0 do
            case Zclassicex.getblockhash(h) do
              {:ok, hash} ->
                case Zclassicex.getblock(hash, 1) do
                  {:ok, block} -> block
                  _ -> nil
                end
              _ -> nil
            end
          end
          |> Enum.reject(&is_nil/1)

        render(conn, "blocks.html",
          blocks_data: blocks_data,
          date: today_str,
          disable_next: disable_next,
          disable_previous: disable_previous,
          previous: previous,
          page_title: "Zclassic latest blocks"
        )

      {:error, _reason} ->
        render(conn, "blocks.html",
          blocks_data: [],
          date: today_str,
          disable_next: disable_next,
          disable_previous: disable_previous,
          previous: previous,
          page_title: "Zclassic latest blocks"
        )
    end
  end
end
