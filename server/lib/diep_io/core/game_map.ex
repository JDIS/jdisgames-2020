defmodule DiepIO.Core.GameMap do
  @moduledoc false

  alias DiepIO.Core.Position

  @width 5_000
  @height 5_000

  @spec width() :: integer()
  def width, do: @width

  @spec height() :: integer()
  def height, do: @height

  @spec center() :: Position.t()
  def center, do: Position.new(div(@width, 2), div(@height, 2))
end
