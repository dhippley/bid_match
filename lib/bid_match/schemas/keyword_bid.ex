defmodule BidMatch.KeywordBid do
  @moduledoc """
  The schema for the Keyword Bid model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :keyword, :string
    field :bid, :decimal
  end

  def changeset(keyword_bid, attrs) do
    cast(keyword_bid, attrs, [:keyword, :bid])
  end
end
