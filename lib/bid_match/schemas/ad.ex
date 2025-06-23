defmodule BidMatch.Ad do
  @moduledoc """
  The schema for the Ad model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :ad_id, :integer
    field :ad_width, :integer
    field :ad_height, :integer
    field :default_bid, :decimal

    embeds_many :keyword_bid, BidMatch.KeywordBid
  end

  def new(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [
      :ad_id,
      :ad_width,
      :ad_height,
      :default_bid
    ])
    |> cast_embed(:keyword_bid, with: &BidMatch.KeywordBid.changeset/2)
    |> apply_changes()
  end
end
