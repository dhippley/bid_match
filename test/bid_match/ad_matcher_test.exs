defmodule BidMatch.AdMatcherTest do
  use ExUnit.Case, async: false

  alias BidMatch.AdMatcher
  alias BidMatch.AdServer

  setup do
    # Start the AdServer and populate it with test data
    case AdServer.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    # Ensure the AdServer is populated with test data
    ads = [
      %{
        ad_id: 1001,
        ad_width: 320,
        ad_height: 250,
        default_bid: 1.0,
        keyword_bid: [%{keyword: "mazda", bid: 1.5}, %{keyword: "cars", bid: 1.0}]
      },
      %{
        ad_id: 1002,
        ad_width: 300,
        ad_height: 250,
        default_bid: 0.5,
        keyword_bid: [%{keyword: "toyota", bid: 1.0}, %{keyword: "cars", bid: 0.8}]
      },
      %{
        ad_id: 1003,
        ad_width: 320,
        ad_height: 250,
        default_bid: 2.0,
        keyword_bid: [%{keyword: "honda", bid: 1.2}, %{keyword: "vehicles", bid: 1.0}]
      }
    ]

    AdServer.update_ads(ads)

    :ok
  end

  test "find_matching_ad/3 returns the ad with the highest bid for matching keywords and size" do
    keywords = ["mazda", "cars"]
    height = 250
    width = 320

    ad = AdMatcher.find_matching_ad(keywords, height, width)

    assert ad.id == 1001
    assert ad.bid == 1.5
  end

  test "find_matching_ad/3 returns %{id: 0, bid: 0.0} when no keywords match" do
    keywords = ["unknown"]
    height = 250
    width = 320

    ad = AdMatcher.find_matching_ad(keywords, height, width)

    assert ad.id == 0
    assert ad.bid == 0.0
  end
end
