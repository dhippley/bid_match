defmodule BidMatch.AdServer do
  @moduledoc """
  The `AdServer` is a GenServer responsible for managing ad data.

  This module handles reading, parsing, building, storing, and retrieving ad data from the `ads.txt` file.
  It creates `Ad` structs from the parsed and sanitized line data and stores them in the GenServer state.

  An inverted index is built from the data, allowing ads to be retrieved by their keywords nested in the `keyword_bid` field.
  """

  use GenServer

  alias BidMatch.Ad

  @name {:global, __MODULE__}
  @file_name "ads.txt"
  @file_path "priv/data_source"
  @ad_file @file_path <> "/" <> @file_name

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @name)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    ads = @ad_file |> parse_ad_file() |> Enum.map(&Ad.new/1)
    new_state = build_inverted_indexes(ads)
    {:ok, new_state}
  end

  def process_ad_file do
    GenServer.call(@name, :process_ad_file)
  end

  @impl true
  def handle_call(:process_ad_file, _from, _state) do
    ads = @ad_file |> parse_ad_file() |> Enum.map(&Ad.new/1)
    new_state = build_inverted_indexes(ads)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.ads, state}
  end

  @impl true
  def handle_call({:get_ad_by_id, ad_id}, _from, state) do
    ad = Enum.find(state.ads, fn ad -> ad.ad_id == ad_id end)
    {:reply, ad, state}
  end

  @impl true
  def handle_cast({:update_ad, updated_ad}, state) do
    # Remove the old ad from the ETS table
    :ets.match_delete(:ads_inverted_index, {updated_ad.ad_id, :_})

    # Insert the updated ad into the ETS table
    Enum.each(updated_ad.keyword_bid, fn %{keyword: keyword, bid: _} ->
      :ets.insert(:ads_inverted_index, {keyword, updated_ad})
    end)

    # Update the state with the new ad
    new_ads =
      Enum.map(state.ads, fn ad ->
        if ad.ad_id == updated_ad.ad_id, do: updated_ad, else: ad
      end)

    new_state = %{state | ads: new_ads}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_ads, updated_ads}, state) do
    Enum.each(updated_ads, fn updated_ad ->
      :ets.match_delete(:ads_inverted_index, {updated_ad.ad_id, :_})
    end)

    # Insert the updated ads into the ETS table
    Enum.each(updated_ads, fn updated_ad ->
      Enum.each(updated_ad.keyword_bid, fn %{keyword: keyword, bid: _} ->
        :ets.insert(:ads_inverted_index, {keyword, updated_ad})
      end)
    end)

    # Update the state with the new ads
    new_ads =
      Enum.map(state.ads, fn ad ->
        case Enum.find(updated_ads, fn updated_ad -> updated_ad.ad_id == ad.ad_id end) do
          nil -> ad
          updated_ad -> updated_ad
        end
      end)

    new_state = %{state | ads: new_ads}
    {:noreply, new_state}
  end

  def update_ad(updated_ad) do
    GenServer.cast(@name, {:update_ad, updated_ad})
  end

  def update_ads(updated_ads) do
    GenServer.cast(@name, {:update_ads, updated_ads})
  end

  def get_ad_by_id(ad_id) do
    GenServer.call(@name, {:get_ad_by_id, ad_id})
  end

  def parse_ad_file(file_path) do
    start_time = System.monotonic_time()
    :telemetry.execute([:bid_match, :ad_server, :parse_ad_file, :start], %{}, %{})

    ads =
      file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.map(&parse_line/1)
      |> Enum.to_list()

    end_time = System.monotonic_time()
    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    :telemetry.execute([:bid_match, :ad_server, :parse_ad_file, :stop], %{duration: duration}, %{})

    ads
  end

  defp parse_line(line) do
    [ad_info, keyword_list] =
      line
      |> String.split(~r/, (?=\[)/, parts: 2)
      |> Enum.map(&String.trim/1)

    [ad_id, ad_width, ad_height, default_bid] =
      ad_info
      |> String.split(", ")
      |> Enum.map(&String.trim/1)

    keyword_list =
      keyword_list
      |> String.trim_leading("[")
      |> String.trim_trailing("]")
      |> String.split(", ")
      |> Enum.chunk_every(2)
      |> Enum.map(fn [keyword, bid] -> {keyword, String.to_float(bid)} end)
      |> sanitize_keywords()

    %{
      ad_id: String.to_integer(ad_id),
      ad_width: String.to_integer(ad_width),
      ad_height: String.to_integer(ad_height),
      default_bid: String.to_float(default_bid),
      keyword_bid: keyword_list
    }
  end

  defp sanitize_keywords(keywords) do
    Enum.map(keywords, fn {keyword, bid} ->
      sanitized_keyword = String.trim(keyword, "\"")
      %{keyword: sanitized_keyword, bid: bid}
    end)
  end

  defp build_inverted_indexes(ads) do
    start_time = System.monotonic_time()
    :telemetry.execute([:bid_match, :ad_server, :build_inverted_indexes, :start], %{}, %{})

    :ets.new(:ads_inverted_index, [:named_table, :set, :public])

    Enum.each(ads, fn ad ->
      Enum.each(ad.keyword_bid, fn %{keyword: keyword, bid: _} ->
        :ets.insert(:ads_inverted_index, {keyword, ad})
      end)
    end)

    end_time = System.monotonic_time()
    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    :telemetry.execute([:bid_match, :ad_server, :build_inverted_indexes, :stop], %{duration: duration}, %{})

    %{ads: ads, use_indexing: true, indexing_type: :inverted}
  end

  def get_state do
    GenServer.call(@name, :get_state)
  end

  def get_ads_by_keyword(keyword) do
    :ads_inverted_index
    |> :ets.lookup(keyword)
    |> Enum.map(fn {_keyword, ad} -> ad end)
  end
end
