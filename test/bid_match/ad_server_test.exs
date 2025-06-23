defmodule BidMatch.AdServerTest do
  use ExUnit.Case, async: true

  alias BidMatch.AdServer

  setup do
    case AdServer.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  test "process_ad_file/2 processes the ad file and builds inverted indexes" do
    ads = AdServer.get_state()
    assert length(ads) > 0

    keyword = hd(ads).keyword_bid |> hd() |> Map.get(:keyword)
    assert length(AdServer.get_ads_by_keyword(keyword)) > 0
  end

  test "get_state/0 returns the current state of ads" do
    ads = AdServer.get_state()
    assert length(ads) > 0
  end

  test "get_ads_by_keyword/1 returns ads matching the given keyword" do
    ads = AdServer.get_state()
    keyword = hd(ads).keyword_bid |> hd() |> Map.get(:keyword)
    matching_ads = AdServer.get_ads_by_keyword(keyword)
    assert length(matching_ads) > 0
  end

  test "update_ad/1 updates an existing ad" do
    ads = AdServer.get_state()
    ad = hd(ads)
    updated_ad = %{ad | default_bid: 5.0}

    AdServer.update_ad(updated_ad)

    updated_ads = AdServer.get_state()
    assert Enum.any?(updated_ads, fn ad -> ad.default_bid == 5.0 end)
  end

  test "update_ads/1 updates multiple ads" do
    ads = AdServer.get_state()
    ad1 = Enum.at(ads, 0)
    ad2 = Enum.at(ads, 1)
    updated_ad1 = %{ad1 | default_bid: 5.0}
    updated_ad2 = %{ad2 | default_bid: 6.0}

    AdServer.update_ads([updated_ad1, updated_ad2])

    updated_ads = AdServer.get_state()
    assert Enum.any?(updated_ads, fn ad -> ad.default_bid == 5.0 end)
    assert Enum.any?(updated_ads, fn ad -> ad.default_bid == 6.0 end)
  end

  test "parse_ad_file/1 parses the ad file and returns a list of ads" do
    ads = AdServer.parse_ad_file("priv/data_source/ads.txt")
    assert length(ads) > 0
  end

  test "build_inverted_indexes/1 builds inverted indexes for ads" do
    AdServer.parse_ad_file("priv/data_source/ads.txt")
    state = AdServer.get_state()
    assert length(state) > 0

    keyword = hd(state).keyword_bid |> hd() |> Map.get(:keyword)
    assert length(AdServer.get_ads_by_keyword(keyword)) > 0
  end
end
