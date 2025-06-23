# BidMatch

BidMatch is a high-performance Elixir/Phoenix application for matching advertising requests to available ads using size and keyword criteria. It is optimized for processing large request volumes and supports real-time updates to ad data.

## Overview

- Loads and indexes ads from `ads.txt` for fast lookup.
- Processes bid requests from `request.log` and HTTP endpoints.
- Matches ads by exact size and at least one keyword.
- Outputs results to files in the `priv/` directory.
- Supports live updates to ad keywords and bids.
- Includes telemetry and a LiveView dashboard for monitoring.
- No database required; Ecto schemas are used for data modeling only.

## Quick Start

1. Install dependencies:

   ```sh
   mix setup
   ```

2. Start the server:

   ```sh
   mix phx.server
   # or
   iex -S mix phx.server
   ```

3. Open [http://localhost:4000](http://localhost:4000) in your browser.

## Matching Rules

- Ads must match the request's size exactly.
- At least one keyword must match.
- If a match is found: output `ad_id, max_bid`.
- If no match: output `0, 0.0`.

## Updating Ads

- Ad data is managed in a GenServer and ETS.
- Use provided update functions to change keywords or bids at runtime.

## Testing

Run all tests with:

```sh
mix test
```

## License

See `LICENSE` file for details.