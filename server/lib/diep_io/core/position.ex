defmodule Diep.Io.Core.Position do
  @moduledoc false

  alias :math, as: Math
  alias Diep.Io.Core.GameMap
  alias Diep.Io.Helpers.Angle
  alias Jason.Encoder

  @type t :: {integer, integer}

  @spec new(t(), t(), non_neg_integer) :: t()
  def new(from, to, speed) do
    travel(from, to, speed, distance(from, to))
  end

  @spec new() :: t()
  def new do
    {0, 0}
  end

  @spec random() :: t()
  def random do
    {
      Enum.random(0..GameMap.width()),
      Enum.random(0..GameMap.height())
    }
  end

  defimpl Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Encoder.List.encode(options)
    end
  end

  defp travel(_from, to, speed, distance) when distance <= speed, do: to

  defp travel({x, y} = from, to, speed, _distance) do
    angle = Angle.radian(from, to)

    {
      (speed * Math.cos(angle) + x) |> Kernel.trunc(),
      (speed * Math.sin(angle) + y) |> Kernel.trunc()
    }
  end

  defp distance({x1, y1}, {x2, y2}) do
    Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2))
  end
end
