defmodule BidMatch.RequestTracker do
  @moduledoc """
  A simple GenServer to manage the state of the requests processed form `requests.log`
  to prevent duplicate processing.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %MapSet{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def mark_processed(line) do
    GenServer.call(__MODULE__, {:mark_processed, line})
  end

  def processed?(line) do
    GenServer.call(__MODULE__, {:processed?, line})
  end

  @impl true
  def handle_call({:mark_processed, line}, _from, state) do
    {:reply, :ok, MapSet.put(state, line)}
  end

  @impl true
  def handle_call({:processed?, line}, _from, state) do
    {:reply, MapSet.member?(state, line), state}
  end
end
