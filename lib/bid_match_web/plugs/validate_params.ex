defmodule BidMatchWeb.Plugs.ValidateParams do
  @moduledoc false
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn

  @ck_bid_params ~w(kw size)a
  @kal_el_params ~w(keywords ad_width ad_height)a

  def init(default), do: default

  def call(conn, _opts) do
    params = conn.params

    case validate_params(conn.request_path, params) do
      :ok ->
        conn

      {:error, missing_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Missing required parameters", missing_params: missing_params})
        |> halt()
    end
  end

  defp validate_params("/api/ck_bid", params) do
    validate_required_params(@ck_bid_params, params)
  end

  defp validate_params("/api/kal_el", params) do
    validate_required_params(@kal_el_params, params)
  end

  defp validate_required_params(required_params, params) do
    params = Map.keys(params)

    missing_params =
      Enum.reject(required_params, fn param -> Enum.member?(params, to_string(param)) end)

    if missing_params == [] do
      :ok
    else
      {:error, missing_params}
    end
  end
end
