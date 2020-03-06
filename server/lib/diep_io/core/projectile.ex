defmodule Diep.Io.Core.Projectile do
  @moduledoc false

  alias Diep.Io.Core.Position

  @default_radius 15
  @default_speed 20
  @default_hp 10

  @derive {Jason.Encoder, except: [:hp]}
  @enforce_keys [:owner_id, :radius, :speed, :damage, :position, :to]
  defstruct [:owner_id, :radius, :speed, :damage, :position, :to, :hp]

  @type t :: %__MODULE__{
          owner_id: integer,
          radius: integer,
          speed: integer,
          damage: integer,
          position: Position.t(),
          to: Position.t(),
          hp: integer
        }

  @spec new(integer, Position.t(), Position.t(), integer, Enum.t()) :: t()
  def new(owner_id, from, to, damage, opts \\ []) do
    struct(
      %__MODULE__{
        owner_id: owner_id,
        radius: @default_radius,
        speed: @default_speed,
        damage: damage,
        position: from,
        to: to,
        hp: @default_hp
      },
      opts
    )
  end

  @spec remove_hp(t(), integer) :: t()
  def remove_hp(projectile, amount) do
    %{projectile | hp: projectile.hp - amount}
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
