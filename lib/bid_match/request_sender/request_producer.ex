defmodule BidMatch.RequestProducer do
  @moduledoc """
  A GenStage producer that reads requests from a log file and produces events for downstream consumers.
  """

  use GenStage

  @request_file_path "priv/data_source/requests.log"

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  @impl true
  def init(_opts) do
    lines = @request_file_path |> File.stream!() |> Enum.to_list()
    :telemetry.execute([:bid_match, :file_producer, :init], %{file_path: @request_file_path, line_count: length(lines)})
    {:producer, %{file_path: @request_file_path, demand: 0, lines: lines}}
  end

  @impl true
  def handle_demand(demand, state) do
    start_time = System.monotonic_time()
    state = %{state | demand: state.demand + demand}
    {events, new_state} = dispatch_events(state)
    duration = System.monotonic_time() - start_time

    :telemetry.execute([:bid_match, :file_producer, :handle_demand], %{
      duration: duration,
      demand: demand,
      events_count: length(events)
    })

    {:noreply, events, new_state}
  end

  defp dispatch_events(state) do
    {events, remaining_lines} = Enum.split(state.lines, state.demand)
    new_state = %{state | lines: remaining_lines, demand: state.demand - length(events)}
    {events, new_state}
  end
end
