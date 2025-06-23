defmodule BidMatch.AdMatcher do
  @moduledoc """
  The AdMatcher module is responsible for finding matching ads based on the given keywords, height, and width.

  All operations are timed and logged using Telemetry.
  """

  alias BidMatch.AdServer

  @doc """
  Finds a matching ad based on the given keywords, height, and width.
  Returns the ad with the highest bid if multiple ads match.
  """
  def find_matching_ad(keywords, height, width) when is_list(keywords) do
    start_time = System.monotonic_time()

    ads =
      keywords
      |> Task.async_stream(&AdServer.get_ads_by_keyword/1, max_concurrency: System.schedulers_online())
      |> Enum.flat_map(fn {:ok, ads} -> ads end)

    matching_ads = Enum.filter(ads, fn ad -> match_ad?(ad, keywords, height, width) end)

    result =
      Enum.max_by(matching_ads, &ad_bid(&1, keywords), fn -> nil end)

    end_time = System.monotonic_time()
    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)

    matched_keywords = matching_ads |> Enum.flat_map(fn ad -> get_matched_keywords(ad, keywords) end) |> Enum.uniq()
    matched_bid = result |> ad_bid(keywords) |> Decimal.to_float()

    :telemetry.execute([:bid_match, :ad_matcher, :find_matching_ad], %{duration: duration}, %{
      keywords: keywords,
      height: height,
      width: width
    })

    if result do
      :telemetry.execute([:bid_match, :ad_matcher, :matched_ad], %{count: 1}, %{
        keywords: keywords,
        matched_keywords: matched_keywords,
        height: height,
        width: width,
        ad_id: result.ad_id,
        bid: matched_bid
      })

      %{id: result.ad_id, bid: matched_bid}
    else
      :telemetry.execute([:bid_match, :ad_matcher, :unmatched_ad], %{count: 1}, %{
        keywords: keywords,
        height: height,
        width: width
      })

      %{id: 0, bid: 0.0}
    end
  end

  defp match_ad?(%{ad_width: ad_width, ad_height: ad_height, keyword_bid: keyword_bid}, keywords, height, width) do
    ad_width == width and ad_height == height and
      Enum.any?(keyword_bid, fn %{keyword: keyword, bid: _} -> keyword in keywords end)
  end

  defp get_matched_keywords(%{keyword_bid: keyword_bid}, keywords) do
    keyword_bid
    |> Enum.filter(fn %{keyword: keyword} -> keyword in keywords end)
    |> Enum.map(& &1.keyword)
  end

  def ad_bid(nil, _), do: Decimal.new("0.0")

  def ad_bid(%{default_bid: default_bid, keyword_bid: keyword_bid}, keywords) do
    default_bid =
      case default_bid do
        %Decimal{} -> default_bid
        _ -> Decimal.from_float(default_bid)
      end

    bid =
      Enum.find_value(keyword_bid, default_bid, fn %{keyword: keyword, bid: bid} ->
        if keyword in keywords do
          case bid do
            %Decimal{} -> bid
            _ -> Decimal.from_float(bid)
          end
        end
      end)

    if Decimal.equal?(bid, Decimal.new("0.0")), do: default_bid, else: bid
  end
end
