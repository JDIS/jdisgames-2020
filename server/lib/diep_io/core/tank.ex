defmodule Diep.Io.Core.Tank do
  @moduledoc false

  alias Diep.Io.Core.{Entity, Position, Projectile, Upgrade}
  alias Diep.Io.Helpers.Angle
  alias :math, as: Math

  @default_hp 100
  @default_speed 10
  @default_fire_rate 5
  @default_projectile_damage 20
  @default_body_damage 20
  @default_radius 25

  @upgrade_rates [
    max_hp: &Upgrade.max_hp/1,
    speed: &Upgrade.speed/1,
    fire_rate: &Upgrade.fire_rate/1,
    projectile_damage: &Upgrade.projectile_damage/1,
    body_damage: &Upgrade.body_damage/1
  ]

  @derive Jason.Encoder
  @enforce_keys [
    :id,
    :name,
    :current_hp,
    :max_hp,
    :speed,
    :position,
    :fire_rate,
    :projectile_damage,
    :score
  ]
  defstruct [
    :id,
    :name,
    :max_hp,
    :current_hp,
    :speed,
    :position,
    :score,
    :fire_rate,
    :projectile_damage,
    :body_damage,
    cooldown: 0,
    experience: 0,
    cannon_angle: 0,
    upgrade_tokens: 0,
    upgrade_levels: [max_hp: 0, speed: 0, fire_rate: 0, projectile_damage: 0, body_damage: 0]
  ]

  @type t :: %__MODULE__{
          id: integer,
          name: String.t(),
          max_hp: integer,
          current_hp: integer,
          speed: integer,
          experience: integer,
          position: Position.t(),
          score: integer,
          fire_rate: number,
          cooldown: number,
          projectile_damage: integer,
          body_damage: integer,
          cannon_angle: number()
        }

  defimpl Entity do
    alias Diep.Io.Core.Tank

    @spec get_position(Tank.t()) :: Position.t()
    def get_position(tank), do: tank.position

    @spec get_radius(Tank.t()) :: integer
    def get_radius(_tank), do: Tank.default_radius()

    @spec get_body_damage(Tank.t()) :: integer
    def get_body_damage(_tank), do: Tank.default_body_damage()
  end

  @spec new(integer, String.t()) :: t()
  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      current_hp: @default_hp,
      max_hp: @default_hp,
      speed: @default_speed,
      position: Position.random(),
      score: 0,
      fire_rate: @default_fire_rate,
      projectile_damage: @default_projectile_damage,
      body_damage: @default_body_damage
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
  def add_experience(tank, amount) do
    token_to_add = get_token_amount_from_experience(tank.experience + amount) - upgrade_tokenss_spent(tank)

    tank
    |> add_to_value(:experience, amount)
    |> add_upgrade_tokens(token_to_add)
  end

  @spec add_upgrade_tokens(t(), integer) :: t()
  def add_upgrade_tokens(tank, amount), do: add_to_value(tank, :upgrade_tokens, amount)

  @spec move(t(), Position.t()) :: t()
  def move(tank, position) do
    set_value(tank, :position, position)
  end

  @spec increase_score(t(), integer()) :: t()
  def increase_score(tank, amount) do
    add_to_value(tank, :score, amount)
  end

  @spec shoot(t(), Position.t()) :: {t(), Projectile.t() | nil}
  def shoot(%__MODULE__{cooldown: cooldown} = tank, target) when cooldown <= 0 do
    angle = Angle.radian(tank.position, target)
    projectile = Projectile.new(tank.id, tank.position, angle, tank.projectile_damage)

    updated_tank =
      tank
      |> set_cooldown
      |> set_cannon_angle(target)

    {updated_tank, projectile}
  end

  def shoot(tank, _target), do: {tank, nil}

  @spec set_cooldown(t()) :: t()
  def set_cooldown(tank) do
    add_to_value(tank, :cooldown, tank.fire_rate)
  end

  @spec decrease_cooldown(t()) :: t()
  def decrease_cooldown(%__MODULE__{cooldown: cooldown} = tank) when cooldown <= 0, do: tank

  def decrease_cooldown(tank) do
    remove_from_value(tank, :cooldown, 1)
  end

  @spec set_cannon_angle(t(), Position.t()) :: t()
  def set_cannon_angle(tank, target) do
    angle = Angle.degree(tank.position, target)
    set_value(tank, :cannon_angle, angle)
  end

  @spec buy_max_hp_upgrade(t()) :: t()
  def buy_max_hp_upgrade(tank), do: buy_upgrade(tank, :max_hp)

  @spec buy_speed_upgrade(t()) :: t()
  def buy_speed_upgrade(tank), do: buy_upgrade(tank, :speed)

  @spec buy_projectile_damage_upgrade(t()) :: t()
  def buy_projectile_damage_upgrade(tank), do: buy_upgrade(tank, :projectile_damage)

  @spec buy_fire_rate_upgrade(t()) :: t()
  def buy_fire_rate_upgrade(tank), do: buy_upgrade(tank, :fire_rate)

  @spec buy_body_damage_upgrade(t()) :: t()
  def buy_body_damage_upgrade(tank), do: buy_upgrade(tank, :body_damage)

  @spec default_hp() :: integer
  def default_hp, do: @default_hp

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  @spec default_fire_rate() :: number
  def default_fire_rate, do: @default_fire_rate

  @spec default_projectile_damage() :: integer
  def default_projectile_damage, do: @default_projectile_damage

  @spec default_radius() :: integer()
  def default_radius, do: @default_radius

  @spec default_body_damage() :: integer()
  def default_body_damage, do: @default_body_damage

  defp buy_upgrade(%__MODULE__{upgrade_tokens: 0} = tank, _stat), do: tank

  defp buy_upgrade(tank, stat) do
    tank
    |> remove_from_value(:upgrade_tokens, 1)
    |> set_value(stat, calculate_new_stat_value(tank, stat))
    |> increase_stat_level(stat)
  end

  defp add_to_value(tank, field, amount),
    do: Map.update!(tank, field, &(&1 + amount))

  defp remove_from_value(tank, field, amount),
    do: add_to_value(tank, field, -amount)

  defp set_value(tank, field, value), do: Map.replace!(tank, field, value)

  defp increase_stat_level(tank, stat) do
    %{tank | upgrade_levels: Keyword.update!(tank.upgrade_levels, stat, &(&1 + 1))}
  end

  defp calculate_new_stat_value(tank, stat) do
    func = Keyword.get(@upgrade_rates, stat, & &1)

    Map.get(tank, stat, 0)
    |> func.()
  end

  defp upgrade_tokenss_spent(tank) do
    tank.upgrade_levels
    |> Keyword.values()
    |> Enum.sum()
  end

  defp get_token_amount_from_experience(exp) do
    exp
    |> Math.log2()
    |> Kernel.*(0.5)
    |> Kernel.floor()
  end
end
