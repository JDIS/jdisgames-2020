defmodule DiepIO.Core.Position do
  @moduledoc false

  alias :math, as: Math
  alias DiepIO.Core.GameMap
  alias DiepIO.Helpers.Angle
  alias Jason.Encoder

  @type t :: {integer, integer}

  @spec new() :: t()
  def new(x \\ 0, y \\ 0) do
    {x, y}
  end

  @spec next(t(), t() | float, integer) :: t()
  def next(from, angle, speed) when is_number(angle) do
    from_angle(from, angle, speed)
  end

  def next(from, to, speed) do
    from_destination(from, to, speed, distance(from, to))
  end

  @spec random() :: t()
  def random do
    {
      Enum.random(0..GameMap.width()),
      Enum.random(0..GameMap.height())
    }
  end

  @spec distance(t(), t()) :: float
  def distance({x1, y1}, {x2, y2}) do
    Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2))
  end

  @spec add(t(), t()) :: t()
  def add({a_x, a_y}, {b_x, b_y}), do: new(a_x + b_x, a_y + b_y)

  defimpl Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Encoder.List.encode(options)
    end
  end

  defp from_destination(_from, to, speed, distance) when distance <= speed, do: to

  defp from_destination(from, to, speed, _distance) do
    angle = Angle.radian(from, to)
    from_angle(from, angle, speed)
  end

  defp from_angle({x, y}, angle, speed) do
    {
      (speed * Math.cos(angle) + x) |> Kernel.trunc(),
      (speed * Math.sin(angle) + y) |> Kernel.trunc()
    }
  end
end
