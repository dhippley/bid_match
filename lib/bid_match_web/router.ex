defmodule BidMatchWeb.Router do
  use BidMatchWeb, :router

  alias BidMatchWeb.Plugs.ValidateParams

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BidMatchWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BidMatchWeb do
    pipe_through :browser

    live "/telemetry", TelemetryLive
    live "/", TelemetryLive
  end

  scope "/api", BidMatchWeb do
    pipe_through :api

    # Use the custom plug to validate required params
    post "/receive_request", RequestController, :receive_request, plug: ValidateParams
    post "/ck_bid", RequestController, :chk_bid, plug: ValidateParams
    post "/kal_el", RequestController, :kal_el, plug: ValidateParams
  end

  # Other scopes may use custom stacks.
  # scope "/api", BidMatchWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bid_match, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BidMatchWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
