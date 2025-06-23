defmodule BidMatchWeb.TelemetryLive do
  @moduledoc false
  use BidMatchWeb, :live_view

  alias BidMatchWeb.TelemetryHandler

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :update_events)

    {:ok,
     assign(socket,
       events: [],
       matched_ads_events: [],
       unmatched_ads_events: [],
       average_duration: 0,
       total_matched_ads: 0,
       total_unmatched_ads: 0
     )}
  end

  @impl true
  def handle_info(:update_events, socket) do
    matched_ads_events = TelemetryHandler.get_matched_ads_events()
    unmatched_ads_events = TelemetryHandler.get_unmatched_ads_events()
    average_duration_ms = TelemetryHandler.get_average_duration()
    total_matched_ads = length(matched_ads_events)
    total_unmatched_ads = length(unmatched_ads_events)

    {:noreply,
     assign(socket,
       matched_ads_events: matched_ads_events,
       unmatched_ads_events: unmatched_ads_events,
       average_duration: average_duration_ms,
       total_matched_ads: total_matched_ads,
       total_unmatched_ads: total_unmatched_ads
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 flex flex-col space-y-4 max-w-7xl">
      <div class="flex space-x-4">
        <div class="bg-white shadow-md rounded-lg p-6 inline-block max-w-full h-48 overflow-y-scroll flex-1">
          <h2 class="text-xl font-semibold mb-4">Average Duration of find_matching_ad Attempts</h2>
          <p class="text-lg">{@average_duration} ms</p>
        </div>

        <div class="bg-white shadow-md rounded-lg p-6 inline-block max-w-full h-48 overflow-y-scroll flex-1">
          <h2 class="text-xl font-semibold mb-4">Request Counts</h2>
          <p class="text-lg"><b>Matched Requests:</b> {@total_matched_ads}</p>
          <p class="text-lg"><b>UnMatched Requests:</b> {@total_unmatched_ads}</p>
        </div>
      </div>

      <div class="bg-white shadow-md rounded-lg p-6 mb-6 inline-block max-w-full h-96 overflow-y-scroll flex-2">
        <h2 class="text-xl font-semibold mb-4">Matched Ads Events</h2>
        <ul class="list-disc pl-5">
          <%= for event <- @matched_ads_events do %>
            <li class="mb-2">
              <strong>Matched Ad</strong>
              <ul class="list-none pl-0">
                <li>Keywords: {inspect(Map.get(event[:metadata], :keywords, []))}</li>
                <li>Matched Keyword: {inspect(Map.get(event[:metadata], :matched_keywords, []))}</li>
                <li>Height: {inspect(Map.get(event[:metadata], :height, 0))}</li>
                <li>Width: {inspect(Map.get(event[:metadata], :width, 0))}</li>
                <li>Ad ID: {inspect(Map.get(event[:metadata], :ad_id, 0))}</li>
                <li>Bid: {inspect(Map.get(event[:metadata], :bid, 0))}</li>
              </ul>
            </li>
          <% end %>
        </ul>
      </div>

      <div class="bg-white shadow-md rounded-lg p-6 mb-6 inline-block max-w-full h-96 overflow-y-scroll flex-2">
        <h2 class="text-xl font-semibold mb-4">Unmatched Ads Events</h2>
        <ul class="list-disc pl-5">
          <%= for event <- @unmatched_ads_events do %>
            <li class="mb-2">
              <strong>Unmatched Ad</strong>
              <ul class="list-none pl-0">
                <li>Keywords: {inspect(Map.get(event[:metadata], :keywords, []))}</li>
                <li>Height: {inspect(Map.get(event[:metadata], :height, 0))}</li>
                <li>Width: {inspect(Map.get(event[:metadata], :width, 0))}</li>
              </ul>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
