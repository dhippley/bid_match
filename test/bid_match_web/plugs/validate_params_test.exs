defmodule BidMatchWeb.Plugs.ValidateParamsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Phoenix.ConnTest

  alias BidMatchWeb.Plugs.ValidateParams

  @opts ValidateParams.init([])

  describe "call/2" do
    test "returns :ok when required params are present for /api/ck_bid" do
      conn = conn(:post, "/api/ck_bid", %{"kw" => "test", "size" => "320x250"})
      conn = ValidateParams.call(conn, @opts)
      assert conn.status == nil
    end

    test "returns :bad_request when required params are missing for /api/ck_bid" do
      conn = conn(:post, "/api/ck_bid", %{"kw" => "test"})
      conn = ValidateParams.call(conn, @opts)
      assert conn.status == 400

      assert json_response(conn, 400) == %{
               "status" => "error",
               "message" => "Missing required parameters",
               "missing_params" => ["size"]
             }
    end

    test "returns :ok when required params are present for /api/kal_el" do
      conn = conn(:post, "/api/kal_el", %{"keywords" => "test", "ad_width" => "320", "ad_height" => "250"})
      conn = ValidateParams.call(conn, @opts)
      assert conn.status == nil
    end

    test "returns :bad_request when required params are missing for /api/kal_el" do
      conn = conn(:post, "/api/kal_el", %{"keywords" => "test", "ad_width" => "320"})
      conn = ValidateParams.call(conn, @opts)
      assert conn.status == 400

      assert json_response(conn, 400) == %{
               "status" => "error",
               "message" => "Missing required parameters",
               "missing_params" => ["ad_height"]
             }
    end
  end
end
