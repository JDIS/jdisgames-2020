defmodule DiepIO.GameParams do
  @moduledoc false

  alias DiepIO.UpgradeParams

  @type t :: %__MODULE__{
          number_of_ticks: integer(),
          max_debris_count: integer(),
          max_debris_generation_rate: float(),
          score_multiplier: float(),
          hot_zone_points: integer(),
          upgrade_params: upgrade_params()
        }

  @type upgrade_params :: %{
          speed: UpgradeParams.t(),
          max_hp: UpgradeParams.t(),
          projectile_damage: UpgradeParams.t(),
          body_damage: UpgradeParams.t(),
          fire_rate: UpgradeParams.t(),
          hp_regen: UpgradeParams.t(),
          projectile_time_to_live: UpgradeParams.t()
        }

  @enforce_keys [
    :number_of_ticks,
    :max_debris_count,
    :max_debris_generation_rate,
    :score_multiplier,
    :upgrade_params,
    :hot_zone_points
  ]
  defstruct [
    :number_of_ticks,
    :max_debris_count,
    :max_debris_generation_rate,
    :score_multiplier,
    :upgrade_params,
    :hot_zone_points
  ]

  @spec new(%{
          number_of_ticks: integer(),
          max_debris_count: integer(),
          max_debris_generation_rate: float(),
          score_multiplier: float(),
          hot_zone_points: integer(),
          upgrade_params: upgrade_params()
        }) :: t()
  def new(opts) do
    struct!(__MODULE__, opts)
  end

  @spec default_params() :: t()
  def default_params do
    %__MODULE__{
      number_of_ticks: 2000,
      max_debris_count: 200,
      max_debris_generation_rate: 0.05,
      score_multiplier: 1.0,
      hot_zone_points: 6,
      upgrade_params: %{
        speed: %UpgradeParams{upgrade_rate: 0.3, base_value: 10},
        max_hp: %UpgradeParams{upgrade_rate: 0.3, base_value: 50},
        projectile_damage: %UpgradeParams{upgrade_rate: 0.3, base_value: 20},
        body_damage: %UpgradeParams{upgrade_rate: 0.3, base_value: 20},
        fire_rate: %UpgradeParams{upgrade_rate: 0.2, base_value: 25},
        hp_regen: %UpgradeParams{upgrade_rate: 0.3, base_value: 0.25},
        projectile_time_to_live: %UpgradeParams{upgrade_rate: 0.15, base_value: 30}
      }
    }
  end
end
