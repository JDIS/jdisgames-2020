defmodule DiepIO.Helpers.Angle do
  @moduledoc false

  alias :math, as: Math

  @spec radian({number, number}, {number, number}) :: float
  def radian({x1, y1}, {x2, y2}) do
    Math.atan2(y2 - y1, x2 - x1)
  end

  @spec degree({number, number}, {number, number}) :: float
  def degree(p1, p2) do
    radian(p1, p2) / Math.pi() * 180
  end
end
