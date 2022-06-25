defmodule DiepIO.Core.GameMap do
  @moduledoc false

  @width 5_000
  @height 5_000

  @spec width() :: integer()
  def width, do: @width

  @spec height() :: integer()
  def height, do: @height
end
