defmodule Diep.Io.Core.Projectile do
  @moduledoc false

  alias Diep.Io.Core.{Entity, Position}

  @default_radius 15
  @default_speed 100
  @default_hp 10

  @derive {Jason.Encoder, except: [:hp]}
  @enforce_keys [:id, :owner_id, :radius, :speed, :damage, :position, :angle]
  defstruct [:id, :owner_id, :radius, :speed, :damage, :position, :angle, :hp]

  @type t :: %__MODULE__{
          id: integer,
          owner_id: integer,
          radius: integer,
          speed: integer,
          damage: integer,
          position: Position.t(),
          angle: float,
          hp: integer
        }

  defimpl Entity do
    alias Diep.Io.Core.Projectile

    @spec get_position(Projectile.t()) :: Position.t()
    def get_position(projectile), do: projectile.position

    @spec get_radius(Projectile.t()) :: integer
    def get_radius(projectile), do: projectile.radius
  end

  @spec new(integer, Position.t(), float, integer, Enum.t()) :: t()
  def new(owner_id, from, angle, damage, opts \\ []) do
    struct(
      %__MODULE__{
        id: System.unique_integer(),
        owner_id: owner_id,
        radius: @default_radius,
        speed: @default_speed,
        damage: damage,
        position: from,
        angle: angle,
        hp: @default_hp
      },
      opts
    )
  end

  @spec remove_hp(t(), integer) :: t()
  def remove_hp(projectile, amount) do
    %{projectile | hp: projectile.hp - amount}
  end

  @spec move(t()) :: t()
  def move(projectile) do
    %{
      projectile
      | position: Position.next(projectile.position, projectile.angle, projectile.speed)
    }
  end

  @spec is_dead?(t()) :: boolean
  def is_dead?(projectile), do: projectile.hp <= 0

  @spec default_radius() :: integer
  def default_radius, do: @default_radius

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  @spec default_hp() :: integer
  def default_hp, do: @default_hp
end
