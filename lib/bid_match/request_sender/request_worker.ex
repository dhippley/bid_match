defmodule BidMatch.RequestWorker do
  @moduledoc """
  A Broadway pipeline to process requests from `requests.log` and send them to the
  `receive_request` endpoint.

  Requests from the `RequestProducer` are decoded and sent to the endpoint,
  once  sent the `RequestTracker` is updated to prevent duplicate processing.
  """
  use Broadway

  alias Broadway.Message

  @endpoint "http://localhost:4000/api/"
  @concurrency 5

  def start_link(_) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BidMatch.RequestProducer, []},
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        # Adjust concurrency as needed
        default: [concurrency: @concurrency]
      ]
    )
  end

  def transform(line, _opts) do
    %Message{
      data: line,
      acknowledger: Broadway.NoopAcknowledger.init()
    }
  end

  @impl true
  def handle_message(_, %Message{data: line} = message, _context) do
    if !BidMatch.RequestTracker.processed?(line) do
      send_request(line)
      BidMatch.RequestTracker.mark_processed(line)
    end

    message
  end

  defp send_request(line) do
    [exchange | [line | _rest]] =
      line |> String.replace(["\n", "http://bid.simpli.fi/", "http://simpli.fi/"], "") |> String.split("?")

    params = URI.decode_query(line)
    Req.post!("#{@endpoint}#{exchange}", json: %{params: params})
  end
end
