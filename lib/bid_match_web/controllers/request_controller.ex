defmodule BidMatchWeb.RequestController do
  use BidMatchWeb, :controller

  @results_file_path "priv/results_#{:os.system_time(:second)}.txt"

  def chk_bid(conn, %{"params" => params}) do
    keyword = String.split(params["kw"], " ")
    size = String.split(params["size"], "x")
    width = String.to_integer(Enum.at(size, 0))
    height = String.to_integer(Enum.at(size, 1))

    ad = BidMatch.AdMatcher.find_matching_ad(keyword, height, width)

    File.write(@results_file_path, "#{inspect(ad.id)}, #{inspect(ad.bid)}\n", [:append])
    json(conn, %{status: "success"})
  end

  def kal_el(conn, %{"params" => params}) do
    keyword = String.split(params["keywords"], " ")
    width = String.to_integer(params["ad_width"])
    height = String.to_integer(params["ad_height"])

    ad = BidMatch.AdMatcher.find_matching_ad(keyword, height, width)

    File.write(@results_file_path, "#{inspect(ad.id)}, #{inspect(ad.bid)}\n", [:append])
    json(conn, %{status: "success"})
  end
end
