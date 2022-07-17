defmodule DiepIOSchemas.GameParamsSchema do
  @moduledoc """
  Game params represent the various parameters that influnce a game.
  """

  use Ecto.Schema

  alias DiepIOSchemas.UpgradeParamsSchema

  @type t :: %__MODULE__{
          number_of_ticks: integer(),
          max_debris_count: integer(),
          max_debris_generation_rate: float(),
          score_multiplier: float(),
          upgrade_params: upgrade_params()
        }
  @type upgrade_params :: %{
          speed: UpgradeParamsSchema.t(),
          max_hp: UpgradeParamsSchema.t(),
          projectile_damage: UpgradeParamsSchema.t(),
          body_damage: UpgradeParamsSchema.t(),
          fire_rate: UpgradeParamsSchema.t(),
          hp_regen: UpgradeParamsSchema.t(),
          projectile_time_to_live: UpgradeParamsSchema.t()
        }

  @primary_key {:game_name, :string, []}

  schema "game_params" do
    field(:number_of_ticks, :integer)
    field(:max_debris_count, :integer)
    field(:max_debris_generation_rate, :float)
    field(:score_multiplier, :float)

    embeds_one :upgrade_params, Upgrades, on_replace: :update, primary_key: false do
      embeds_one :speed, UpgradeParamsSchema, on_replace: :update
      embeds_one :max_hp, UpgradeParamsSchema, on_replace: :update
      embeds_one :projectile_damage, UpgradeParamsSchema, on_replace: :update
      embeds_one :body_damage, UpgradeParamsSchema, on_replace: :update
      embeds_one :fire_rate, UpgradeParamsSchema, on_replace: :update
      embeds_one :hp_regen, UpgradeParamsSchema, on_replace: :update
      embeds_one :projectile_time_to_live, UpgradeParamsSchema, on_replace: :update
    end
  end
end
