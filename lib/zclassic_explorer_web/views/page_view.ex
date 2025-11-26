defmodule ZclassicExplorerWeb.PageView do
  use ZclassicExplorerWeb, :view

  def price() do
    {:ok, price} = Cachex.get(:price_cache, "price")
    price
  end
end
