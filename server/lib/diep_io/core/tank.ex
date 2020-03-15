defmodule Diep.Io.Core.Tank do
  @moduledoc false

  alias Diep.Io.Core.{Entity, Position, Projectile}
  alias Diep.Io.Helpers.Angle
  alias Diep.Io.Upgrades

  @default_hp 100
  @default_speed 10
  @default_fire_rate 5
  @default_projectile_damage 20
  @default_upgrades %{Diep.Io.Upgrades.MaxHP => 0}
  @default_radius 25

  @derive {Jason.Encoder, except: [:id]}
  @enforce_keys [
    :id,
    :name,
    :current_hp,
    :max_hp,
    :speed,
    :position,
    :fire_rate,
    :projectile_damage
  ]
  defstruct [
    :id,
    :name,
    :max_hp,
    :current_hp,
    :speed,
    :position,
    :fire_rate,
    :projectile_damage,
    cooldown: 0,
    experience: 0,
    cannon_angle: 0,
    upgrades: @default_upgrades
  ]

  @type t :: %__MODULE__{
          id: integer,
          name: String.t(),
          max_hp: integer,
          current_hp: integer,
          speed: integer,
          experience: integer,
          position: Position.t(),
          fire_rate: integer,
          cooldown: integer,
          projectile_damage: integer,
          cannon_angle: integer
        }

  defimpl Entity do
    alias Diep.Io.Core.Tank

    @spec get_position(Tank.t()) :: Position.t()
    def get_position(tank), do: tank.position

    @spec get_radius(Tank.t()) :: integer
    def get_radius(_tank), do: Tank.default_radius()
  end

  @spec new(integer, String.t()) :: t()
  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      current_hp: @default_hp,
      max_hp: @default_hp,
      speed: @default_speed,
      position: Position.new(),
      fire_rate: @default_fire_rate,
      projectile_damage: @default_projectile_damage
    }
  end

  @spec is_dead?(t) :: boolean
  def is_dead?(tank), do: tank.current_hp <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(tank), do: !is_dead?(tank)

  @spec heal(t(), integer) :: t()
  def heal(tank, amount) do
    case tank.current_hp + amount <= tank.max_hp do
      true -> add_to_value(tank, :current_hp, amount)
      false -> set_value(tank, :current_hp, tank.max_hp)
    end
  end

  @spec hit(t(), integer) :: t()
  def hit(tank, amount), do: remove_from_value(tank, :current_hp, amount)

  @spec add_experience(t(), integer) :: t()
  def add_experience(tank, amount), do: add_to_value(tank, :experience, amount)

  @spec increment_max_hp(t(), integer) :: t()
  def increment_max_hp(tank, amount) do
    tank |> add_to_value(:max_hp, amount) |> heal(amount)
  end

  @spec buy_upgrade(t(), term) :: t()
  def buy_upgrade(tank, upgrade) do
    level = Upgrades.level(tank, upgrade)
    price = upgrade.price(level)

    case tank.experience >= price do
      true -> tank |> remove_from_value(:experience, price) |> upgrade.apply()
      false -> tank
    end
  end

  @spec move(t(), Position.t()) :: t()
  def move(tank, position) do
    set_value(tank, :position, position)
  end

  @spec shoot(t(), Position.t()) :: {t(), Projectile.t() | nil}
  def shoot(%__MODULE__{cooldown: 0} = tank, target) do
    projectile = Projectile.new(tank.id, tank.position, target, tank.projectile_damage)

    updated_tank =
      tank
      |> set_cooldown
      |> set_cannon_angle(target)

    {updated_tank, projectile}
  end

  def shoot(tank, _target), do: {tank, nil}

  @spec set_cooldown(t()) :: t()
  def set_cooldown(tank) do
    set_value(tank, :cooldown, tank.fire_rate)
  end

  @spec set_cannon_angle(t(), Position.t()) :: t()
  def set_cannon_angle(tank, target) do
    angle = Angle.degree(tank.position, target) |> Kernel.trunc()
    set_value(tank, :cannon_angle, angle)
  end

  @spec default_hp() :: integer
  def default_hp, do: @default_hp

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  @spec default_fire_rate() :: integer
  def default_fire_rate, do: @default_fire_rate

  @spec default_projectile_damage() :: integer
  def default_projectile_damage, do: @default_projectile_damage

  @spec default_upgrades() :: map
  def default_upgrades, do: @default_upgrades

  @spec default_radius() :: integer()
  def default_radius, do: @default_radius

  defp add_to_value(tank, field, amount),
    do: Map.update!(tank, field, &(&1 + amount))

  defp remove_from_value(tank, field, amount),
    do: add_to_value(tank, field, -amount)

  defp set_value(tank, field, value), do: Map.replace!(tank, field, value)
end
