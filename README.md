# BidMatch

To start your Phoenix server:

  * Run `mix setup` to install and set up dependencies
  * Start the Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Found below is a noted list of the requirements as presented in the original `README` file as well as some details on the app's design and operations.

# Overview

When the app is started, two things happen:

First, the `AdServer` is initialized and begins parsing the `ads.txt` file and building `ads`. These `ads` are stored as the GenServer state. Additionally, the `ads` are indexed by keywords and the index is stored in an `ets` table. The indexed ads are accessible through the `get_ads_by_keyword` function.

Second, the `RequestSender` is started. The `RequestSender`, along with the `FileProducer`, parses the `request.log` file and sends `POST` requests to one of the app's endpoints.

The request received by the endpoint is parsed for the data required to find a matching ad and calls the `AdMatcher` via the `RequestController`.

The `AdMatcher` gets all ads with matching keywords from `AdServer.get_ads_by_keyword()` and attempts to find a size match from those ads and returns the results to the `RequestController`.

The `RequestController` writes the results from `AdMatcher` out to a file.

# Requirements

### Part I

```
1.  Update or replace this README with instructions on how to build and execute
    your code along with any other documentation you choose.  You may also
    include any discussion of your design and Part 3 (see below).
```
I've updated the README and highlighted some details regarding the design of the app to document some choices made and the reasoning for them under the `App Structure` heading. Additional details regarding `Part III` can be found in the `Part III` section.

```
2.  Your code must be in the format of a mix project (e.g., with a `mix.exs`
    file and the standard directory structure).
```
The project has been created as a standalone Phoenix App.

```
3.  Operation of your code may be via the `iex` console; you do not have
    to write a command line application though you may choose to do so.
    Regardless, you must include directions on how to compile and execute your
    code in the README.
```

Instructions on starting the app can also be found at the top of this `README`:

  * Install dependencies via `mix setup`
  * Start the server with `mix phx.server` or inside IEx with `iex -S mix phx.server`

```
4.  Attempt to match each request with an ad.
    * The size of the ad should match exactly.
    * At least one of the keywords must match.
```
A match for a request is only found when a `keyword`, `height`, and `width` match has been found.

[This is handled mostly by `AdMatcher.match_ad?()`](https://github.com/simplifi-challenge/functional-code-challenge-Daniel-Hippley/blob/d9a1eec04cf991b7b47cdc63c02784cab6f9594d/lib/bid_match/ad_matching/ad_matcher.ex#L61-L64)

```
5.  Include a way to write the matches to a file.
    * If a match is found, print out a string with the format `12345, 1.5`
        where 12345 is the id of the matching ad and 1.5 is the
        bid value for the highest-valued matching keyword.
    * If no match is found, print out "0, 0.0".
    * There should be one line of output for each request.
    * The order of the output should match the order of the input.
```

The results of the request are handled by [`AdMatcher.find_matching_ad()`](https://github.com/simplifi-challenge/functional-code-challenge-Daniel-Hippley/blob/d9a1eec04cf991b7b47cdc63c02784cab6f9594d/lib/bid_match/ad_matching/ad_matcher.ex#L39).

The writing of the results to a file is handled in the `BidMatchWeb.RequestController`. The file name is unique based on the timestamp and can be found in `priv/` after starting the server.

### Part II

```
We work with several exchanges, and each one sends us bid requests in
a different format.  Using your code from Part I as a starting point, add
the ability to handle requests that take the form
```
```
http://simpli.fi/kal_el?keywords=cars+mazda&ad_width=320&ad_height=250&user_ip=67.10.32.95&browser_agent=Mozilla%2f5.0%20(compatible%3b%20MSIE%209.0%3b%20Windows%20NT%206.0%3b%20Trident%2f5.0%29
```

This is handled in the [`router`](https://github.com/simplifi-challenge/functional-code-challenge-Daniel-Hippley/blob/d9a1eec04cf991b7b47cdc63c02784cab6f9594d/lib/bid_match_web/router.ex#L26-L33)
and [`RequestController`](https://github.com/simplifi-challenge/functional-code-challenge-Daniel-Hippley/blob/d9a1eec04cf991b7b47cdc63c02784cab6f9594d/lib/bid_match_web/controllers/request_controller.ex#L1) where we can apply unique parsing logic based on the endpoint the request has been sent to.

## Part III

```
You do not have to write code for this part of the challenge unless you choose
to do so.

Our system is able to optimize ad performance by changing keywords and 
bids on-the-fly.  For example, if more users click on the ads when "mazda3" is
a keyword, then we may boost the keyword bid in the above ad to improve our
chances of serving that ad to users who have that keyword.

How would you modify your code to enable the system to enact these changes
_while it is running and processing requests_?  For example, suppose that after
the 5000th request, the keywords and bids for several ads are updated and the
new settings should be used for every subsequent request.

Write some text in your README describing how you would solve this problem.
You can assume that an existing subsystem handles notification of the changes,
you only need to address how you would modify your code to consume the changes
on-the-fly.
```

Because our data is stored in a `GenServer` and `ets` tables, the solution is to ensure our `AdServer` has some access implemented to update the server's state and, when updating the state, ensure the keyword indexes stored in `ets` are also updated. This has been done through `AdServer.update_ad` and `AdServer.update_ads`. So the `update system` would only need to call either of those functions to make the updates on the fly.

## Items of Note

  * This project has no Database requirement. I wanted to use schemas but had no reasonable use for an actual Database. 
    So, the project was created with `--database postgres`, but all connection features have been disabled.
  
## App Structure

  Starting out, I did not have much in mind for design but I understood a couple of things that influenced the design and choice of tools:

    1. I did not see a need for a traditional database but Ecto schemas would be useful.
    2. Between incoming requests, file parsing, and matching, there was going to be a lot of data ingestion.
    3. There are a lot of methods for searching and matching so I wanted to implement a few and allow them to be configured with benchmarking.

  With all that in mind, I got started.

### Schemas

  The `ad` schema was modeled to match the form of data in the `ads.txt` file, that is any line in the file is an `ad` and any `ad` has exactly the fields that were provided in
  the original README.md which are ad_id, width, height, default_bid, keyword_bids. 
  
  A second schema was created to model `keyword_bids` and was associated with the `ad` schema.

### AdServer

  The `ad_server` is a GenServer responsible for reading, parsing, building, storing, and retrieving the ad data from `ads.txt`.

  `ad` structs are created from the parsed and sanitized line data and stored as the GenServer `state`. An inverted index is built from the data allowing `ads` to be retrieved by their keywords nested in 
  the `keyword_bid` field.

  Access to all the `ad` data is provided through the function `get_state/0` while `get_ads_by_keyword/1` allows fetching only ads that match the given keyword.

### Request Sender

  Once we had a way to store and search the ad data, we needed a way to handle the `request.log`. Like `ads.txt`, we needed a way to parse and sanitize the data by line and then use the parsed data to construct
  and send a request to be matched with an ad. The `request.log` file is 10x bigger than the `ads.txt` so we need some concurrency and control and a `Broadway` pipeline with a custom producer gives us exactly that.

  `request_producer.ex` is a GenStage producer that feeds lines parsed from the `request.log` to our pipeline. `request_worker.ex` is a pipeline that will get and transform data from `request_producer.ex` and send a request
  to our endpoint. We also have `request_tracker.ex` which is a simple GenServer used to keep track of which line/requests have already been sent to help prevent duplicate messages from being sent.

### Handling Requests

  Nothing too special happening here. We validate the request has the required params through a custom `plug` and the `request_controller` parses the params and calls `AdMatcher.find_matching_ad`. We write the results to `priv/results_TIMESTAMP.txt`
  as `ad_id, max_bid` if a match was found and `0, 0.0` if no match was found.

### Matching Ads
  
  Similar to the above, nothing magical happening. We call `AdServer.get_ads_by_keyword` and just filter the results for a matching keyword. If multiple matches are found, the highest bid is returned.

### Telemetry
  
  We lean on `telemetry` quite a bit. A `liveview` was built to allow easy viewing of some various metrics as well as the results of incoming requests. The page only has basic styling but includes the Average Duration of `find_matching_ad` Attempts, total counts for `matched` and `unmatched` requests as well as the details of all `matched` and `unmatched` requests.

### Testing

  Some basic unit tests were created to ensure things are running correctly and can be run using `mix test`.