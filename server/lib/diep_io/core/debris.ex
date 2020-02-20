defmodule Diep.Io.Core.Debris do
  @moduledoc false

  alias Diep.Io.Core.Position

  @default_size :small
  @default_hp_map %{small: 20, medium: 50, large: 100}
  @points_map %{small: 10, medium: 20, large: 20}
  @default_speed 1

  @derive Jason.Encoder
  @enforce_keys [:id, :current_hp, :size, :position]
  defstruct [:id, :current_hp, :size, :position, speed: @default_speed]

  @type size_t :: :small | :medium | :large
  @type t :: %__MODULE__{
          id: integer,
          current_hp: integer,
          size: size_t,
          speed: integer,
          position: Position.t()
        }

  @spec new(size_t) :: t()
  def new(size) do
    %__MODULE__{
      current_hp: default_hp(size),
      size: size,
      position: Position.random(),
      id: System.unique_integer()
    }
  end

  @spec new() :: t()
  def new do
    new(@default_size)
  end

  @spec get_points(t()) :: integer
  def get_points(debris) do
    Map.fetch!(@points_map, debris.size)
  end

  @spec hit(t(), integer) :: t()
  def hit(debris, amount), do: remove_from_value(debris, :current_hp, amount)

  @spec is_dead?(t()) :: boolean
  def is_dead?(debris), do: debris.current_hp <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(debris), do: !is_dead?(debris)

  @spec default_hp(size_t) :: integer
  def default_hp(size), do: Map.fetch!(@default_hp_map, size)

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  defp(remove_from_value(tank, field, amount),
    do: Map.update!(tank, field, &(&1 - amount))
  )
end
