defmodule DiepIO.Core.Tank do
  @moduledoc false

  alias DiepIO.Core.{Entity, Position, Projectile, Upgrade}
  alias DiepIO.GameParams
  alias DiepIO.Helpers.Angle
  alias :math, as: Math

  @derive {Jason.Encoder, except: [:upgrade_params]}
  @enforce_keys [
    :id,
    :name,
    :current_hp,
    :max_hp,
    :speed,
    :position,
    :fire_rate,
    :projectile_damage,
    :hp_regen,
    :score,
    :has_died,
    :has_triple_gun,
    :upgrade_params
  ]
  defstruct [
    :id,
    :name,
    :max_hp,
    :current_hp,
    :speed,
    :position,
    :destination,
    :target,
    :score,
    :fire_rate,
    :projectile_damage,
    :body_damage,
    :hp_regen,
    :projectile_time_to_live,
    :upgrade_params,
    has_died: false,
    cooldown: 0,
    experience: 0,
    cannon_angle: 0,
    upgrade_tokens: 0,
    upgrade_levels: %{
      max_hp: 0,
      speed: 0,
      fire_rate: 0,
      projectile_damage: 0,
      body_damage: 0,
      hp_regen: 0,
      projectile_time_to_live: 0
    },
    has_triple_gun: false,
    ticks_alive: 0
  ]

  @type t :: %__MODULE__{
          id: integer,
          name: String.t(),
          max_hp: integer,
          current_hp: number,
          speed: integer,
          experience: integer,
          position: Position.t(),
          destination: Position.t() | nil,
          target: Position.t() | nil,
          score: integer,
          fire_rate: number,
          hp_regen: number,
          cooldown: number,
          projectile_damage: integer,
          body_damage: integer,
          cannon_angle: number(),
          has_died: boolean,
          projectile_time_to_live: integer,
          has_triple_gun: boolean,
          upgrade_params: GameParams.upgrade_params(),
          ticks_alive: integer
        }

  defimpl Entity do
    alias DiepIO.Core.Tank

    @spec get_position(Tank.t()) :: Position.t()
    def get_position(tank), do: tank.position

    @spec get_radius(Tank.t()) :: integer
    def get_radius(_tank), do: Tank.default_radius()

    @spec get_body_damage(Tank.t()) :: integer
    def get_body_damage(tank), do: tank.body_damage
  end

  @spec new(integer, String.t(), GameParams.upgrade_params()) :: t()
  def new(id, name, upgrade_params) do
    %__MODULE__{
      id: id,
      name: name,
      current_hp: upgrade_params[:max_hp].base_value,
      max_hp: upgrade_params[:max_hp].base_value,
      speed: upgrade_params[:speed].base_value,
      position: Position.random(),
      score: 0,
      has_died: false,
      fire_rate: upgrade_params[:fire_rate].base_value,
      projectile_damage: upgrade_params[:projectile_damage].base_value,
      body_damage: upgrade_params[:body_damage].base_value,
      hp_regen: upgrade_params[:hp_regen].base_value,
      projectile_time_to_live: upgrade_params[:projectile_time_to_live].base_value,
      has_triple_gun: false,
      upgrade_params: upgrade_params,
      ticks_alive: 0
    }
  end

  @spec is_dead?(t) :: boolean
  def is_dead?(tank), do: tank.current_hp <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(tank), do: !is_dead?(tank)

  @spec heal(t(), number) :: t()
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
    token_to_add =
      get_token_amount_from_experience(tank.experience + amount) - upgrade_tokens_spent(tank) - tank.upgrade_tokens

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

  @spec set_target(t(), Position.t()) :: t()
  def set_target(tank, target), do: set_value(tank, :target, target)

  @spec set_destination(t(), Position.t()) :: t()
  def set_destination(tank, destination), do: set_value(tank, :destination, destination)

  @spec increase_score(t(), integer()) :: t()
  def increase_score(tank, amount) do
    add_to_value(tank, :score, amount)
  end

  @spec increase_ticks_alive(t(), integer()) :: t()
  def increase_ticks_alive(tank, amount) do
    add_to_value(tank, :ticks_alive, amount)
  end

  @spec shoot(t()) :: {t(), [Projectile.t() | nil]}
  def shoot(%__MODULE__{cooldown: cooldown} = tank) when cooldown <= 0 do
    angle = Angle.radian(tank.position, tank.target)
    projectile1 = Projectile.new(tank.id, tank.position, angle, tank.projectile_damage, tank.projectile_time_to_live)

    projectiles =
      if tank.has_triple_gun do
        projectile2 =
          Projectile.new(tank.id, tank.position, angle - 1, tank.projectile_damage, tank.projectile_time_to_live)

        projectile3 =
          Projectile.new(tank.id, tank.position, angle + 1, tank.projectile_damage, tank.projectile_time_to_live)

        [projectile1, projectile2, projectile3]
      else
        [projectile1]
      end

    updated_tank = set_cooldown(tank)

    {updated_tank, projectiles}
  end

  def shoot(tank), do: {tank, []}

  @spec set_cooldown(t()) :: t()
  def set_cooldown(tank) do
    add_to_value(tank, :cooldown, tank.fire_rate)
  end

  @spec decrease_cooldown(t()) :: t()
  def decrease_cooldown(%__MODULE__{cooldown: cooldown} = tank) when cooldown <= 0, do: tank

  def decrease_cooldown(tank) do
    remove_from_value(tank, :cooldown, 1)
  end

  def set_cannon_angle(tank, nil) do
    set_cannon_angle(tank, tank.position)
  end

  @spec set_cannon_angle(t(), Position.t()) :: t()
  def set_cannon_angle(tank, target) do
    angle = Angle.degree(tank.position, target)
    set_value(tank, :cannon_angle, angle)
  end

  @spec mark_as_dead(t()) :: t()
  def mark_as_dead(tank), do: set_value(tank, :has_died, true)

  @spec mark_as_alive(t()) :: t()
  def mark_as_alive(tank), do: set_value(tank, :has_died, false)

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

  @spec buy_hp_regen_upgrade(t()) :: t()
  def buy_hp_regen_upgrade(tank), do: buy_upgrade(tank, :hp_regen)

  @spec buy_projectile_time_to_live_upgrade(t()) :: t()
  def buy_projectile_time_to_live_upgrade(tank), do: buy_upgrade(tank, :projectile_time_to_live)

  @spec default_radius() :: integer()
  def default_radius, do: 50

  @spec respawn(t()) :: t()
  def respawn(tank), do: new(tank.id, tank.name, tank.upgrade_params)

  defp buy_upgrade(%__MODULE__{upgrade_tokens: upgrade_tokens} = tank, _stat)
       when upgrade_tokens <= 0 do
    tank
  end

  defp buy_upgrade(tank, stat) do
    tank
    |> remove_from_value(:upgrade_tokens, 1)
    |> increase_stat_level(stat)
    |> calculate_new_stat_value(stat, tank.upgrade_params)
  end

  def add_triple_gun(tank) do
    set_value(tank, :has_triple_gun, true)
  end

  defp add_to_value(tank, field, amount),
    do: Map.update!(tank, field, &(&1 + amount))

  defp remove_from_value(tank, field, amount),
    do: add_to_value(tank, field, -amount)

  defp set_value(tank, field, value), do: Map.replace!(tank, field, value)

  defp increase_stat_level(tank, stat) do
    %{tank | upgrade_levels: Map.update!(tank.upgrade_levels, stat, &(&1 + 1))}
  end

  defp calculate_new_stat_value(tank, stat, upgrade_params) do
    level = tank.upgrade_levels[stat]
    new_value = Upgrade.calculate_stat_value(stat, level, upgrade_params)
    set_value(tank, stat, new_value)
  end

  defp upgrade_tokens_spent(tank) do
    tank.upgrade_levels
    |> Map.values()
    |> Enum.sum()
  end

  defp get_token_amount_from_experience(0), do: 0

  defp get_token_amount_from_experience(exp) do
    exp
    |> Math.pow(0.40)
    |> Kernel.floor()
  end
end
