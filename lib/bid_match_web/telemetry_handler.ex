defmodule BidMatchWeb.TelemetryHandler do
  @moduledoc false
  use GenServer

  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :telemetry.attach_many(
      "bid_match-telemetry-handler",
      [
        [:bid_match, :ad_server, :parse_ad_file, :start],
        [:bid_match, :ad_server, :parse_ad_file, :stop],
        [:bid_match, :ad_server, :build_inverted_indexes, :start],
        [:bid_match, :ad_server, :build_inverted_indexes, :stop],
        [:bid_match, :ad_matcher, :find_matching_ad],
        [:bid_match, :ad_matcher, :matched_ad],
        [:bid_match, :ad_matcher, :unmatched_ad],
        [:bid_match, :file_producer, :init],
        [:bid_match, :file_producer, :handle_demand]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    {:ok,
     %{
       find_matching_ad: %{total_duration: 0, count: 0, average_duration: 0},
       build_inverted_indexes: [],
       parse_ad_file: [],
       matched_ad: [],
       unmatched_ad: [],
       file_producer_init: [],
       file_producer_handle_demand: []
     }}
  end

  # Ad Server Events
  def handle_event([:bid_match, :ad_server, :parse_ad_file, :start], _measurements, _metadata, _config) do
    Logger.info("Started parsing ad file")
  end

  def handle_event([:bid_match, :ad_server, :parse_ad_file, :stop], measurements, _metadata, _config) do
    Logger.info("Finished parsing ad file in #{measurements[:duration]} ms")
    GenServer.cast(__MODULE__, {:store_event, :parse_ad_file, measurements})
  end

  def handle_event([:bid_match, :ad_server, :build_inverted_indexes, :start], _measurements, _metadata, _config) do
    Logger.info("Started building inverted indexes")
  end

  def handle_event([:bid_match, :ad_server, :build_inverted_indexes, :stop], measurements, _metadata, _config) do
    Logger.info("Finished building inverted indexes in #{measurements[:duration]} ms")
    GenServer.cast(__MODULE__, {:store_event, :build_inverted_indexes, measurements})
  end

  # Ad Matcher Events
  def handle_event([:bid_match, :ad_matcher, :find_matching_ad], measurements, metadata, _config) do
    Logger.info(
      "Finding matching ad took #{measurements[:duration]} ms with keywords #{inspect(metadata[:keywords])}, height #{metadata[:height]}, width #{metadata[:width]}"
    )

    GenServer.cast(__MODULE__, {:store_event, :find_matching_ad, %{measurements: measurements, metadata: metadata}})
  end

  def handle_event([:bid_match, :ad_matcher, :matched_ad], measurements, metadata, _config) do
    Logger.info("Matched ad with ID #{metadata[:ad_id]} and bid #{metadata[:bid]} (count: #{measurements[:count]})")
    GenServer.cast(__MODULE__, {:store_event, :matched_ad, %{measurements: measurements, metadata: metadata}})
  end

  def handle_event([:bid_match, :ad_matcher, :unmatched_ad], measurements, metadata, _config) do
    Logger.info(
      "No matching ad found for keywords #{inspect(metadata[:keywords])}, height #{metadata[:height]}, width #{metadata[:width]} (count: #{measurements[:count]})"
    )

    GenServer.cast(__MODULE__, {:store_event, :unmatched_ad, %{measurements: measurements, metadata: metadata}})
  end

  # File Producer Events
  def handle_event([:bid_match, :file_producer, :init], measurements, metadata, _config) do
    Logger.info(
      "Initialized file producer with file path #{metadata[:file_path]} and line count #{measurements[:line_count]}"
    )

    GenServer.cast(__MODULE__, {:store_event, :file_producer_init, %{measurements: measurements, metadata: metadata}})
  end

  def handle_event([:bid_match, :file_producer, :handle_demand], measurements, _metadata, _config) do
    Logger.info(
      "Handled demand in file producer with duration #{measurements[:duration]} ms, demand #{measurements[:demand]}, and events count #{measurements[:events_count]}"
    )

    GenServer.cast(__MODULE__, {:store_event, :file_producer_handle_demand, measurements})
  end

  @impl true
  def handle_cast({:store_event, :find_matching_ad, %{measurements: measurements}}, state) do
    total_duration = state.find_matching_ad.total_duration + measurements[:duration]
    count = state.find_matching_ad.count + 1
    average_duration = total_duration / count

    new_state =
      Map.put(state, :find_matching_ad, %{
        total_duration: total_duration,
        count: count,
        average_duration: average_duration
      })

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:store_event, event, data}, state) do
    new_state = Map.update(state, event, [data], fn events -> [data | events] end)
    {:noreply, new_state}
  end

  def get_events do
    GenServer.call(__MODULE__, :get_events)
  end

  def get_average_duration do
    GenServer.call(__MODULE__, :get_average_duration)
  end

  def get_producer_events do
    GenServer.call(__MODULE__, :file_producer_handle_demand)
  end

  def get_matched_ads_events do
    GenServer.call(__MODULE__, :get_matched_ads_events)
  end

  def get_unmatched_ads_events do
    GenServer.call(__MODULE__, :get_unmatched_ads_events)
  end

  @impl true
  def handle_call(:get_events, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_average_duration, _from, state) do
    {:reply, state.find_matching_ad.average_duration, state}
  end

  @impl true
  def handle_call(:get_producer_events, _from, state) do
    {:reply, state.file_producer_handle_demand, state}
  end

  @impl true
  def handle_call(:get_matched_ads_events, _from, state) do
    matched_ads_events = Map.get(state, :matched_ad, [])
    {:reply, matched_ads_events, state}
  end

  @impl true
  def handle_call(:get_unmatched_ads_events, _from, state) do
    unmatched_ads_events = Map.get(state, :unmatched_ad, [])
    {:reply, unmatched_ads_events, state}
  end
end
