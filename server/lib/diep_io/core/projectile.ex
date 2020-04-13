defmodule Diep.Io.Core.Projectile do
  @moduledoc false

  alias Diep.Io.Core.{Entity, Position}

  @default_radius 15
  @default_speed 40
  @default_time_to_live 10

  @derive Jason.Encoder
  @enforce_keys [:id, :owner_id, :radius, :speed, :damage, :position, :angle]
  defstruct [:id, :owner_id, :radius, :speed, :damage, :position, :angle, :time_to_live]

  @type t :: %__MODULE__{
          id: String.t(),
          owner_id: integer,
          radius: integer,
          speed: integer,
          damage: integer,
          position: Position.t(),
          angle: float,
          time_to_live: integer
        }

  defimpl Entity do
    alias Diep.Io.Core.Projectile

    @spec get_position(Projectile.t()) :: Position.t()
    def get_position(projectile), do: projectile.position

    @spec get_radius(Projectile.t()) :: integer
    def get_radius(projectile), do: projectile.radius

    @spec get_body_damage(Projectile.t()) :: integer
    def get_body_damage(projectile), do: projectile.damage
  end

  @spec new(integer, Position.t(), float, integer, Enum.t()) :: t()
  def new(owner_id, from, angle, damage, opts \\ []) do
    struct(
      %__MODULE__{
        id: System.unique_integer() |> to_string(),
        owner_id: owner_id,
        radius: @default_radius,
        speed: @default_speed,
        damage: damage,
        position: from,
        angle: angle,
        time_to_live: @default_time_to_live
      },
      opts
    )
  end

  @spec decrease_time_to_live(t(), integer) :: t()
  def decrease_time_to_live(projectile, amount) do
    %{projectile | time_to_live: projectile.time_to_live - amount}
  end

  @spec move(t()) :: t()
  def move(projectile) do
    %{
      projectile
      | position: Position.next(projectile.position, projectile.angle, projectile.speed)
    }
  end

  @spec is_dead?(t()) :: boolean
  def is_dead?(projectile), do: projectile.time_to_live <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(projectile), do: !is_dead?(projectile)

  @spec default_radius() :: integer
  def default_radius, do: @default_radius

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  @spec default_time_to_live() :: integer
  def default_time_to_live, do: @default_time_to_live
end
