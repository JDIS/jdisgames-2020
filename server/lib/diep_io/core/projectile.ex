defmodule Diep.Io.Core.Projectile do
  @moduledoc false

  @default_radius 15
  @default_speed 20

  @enforce_keys [:radius, :speed, :damage]
  defstruct [:radius, :speed, :damage]

  @type t :: %__MODULE__{
          radius: integer,
          speed: integer,
          damage: integer
        }

  @spec new(float) :: t()
  def new(damage) do
    %__MODULE__{radius: @default_radius, speed: @default_speed, damage: damage}
  end

  @spec default_radius() :: integer
  def default_radius, do: @default_radius

  @spec default_speed() :: integer
  def default_speed, do: @default_speed
end
