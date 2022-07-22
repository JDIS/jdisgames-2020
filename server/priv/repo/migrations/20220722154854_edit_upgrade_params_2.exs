defmodule DiepIO.Repo.Migrations.EditUpgradeParams2 do
  use Ecto.Migration

  def change do
    alter table(:game_params) do
      modify(:upgrade_params, :map,
        null: false,
        default: %{
          speed: %{upgrade_rate: 0.2, base_value: 10},
          max_hp: %{upgrade_rate: 0.3, base_value: 50},
          projectile_damage: %{upgrade_rate: 0.3, base_value: 20},
          body_damage: %{upgrade_rate: 0.3, base_value: 20},
          fire_rate: %{upgrade_rate: 0.20, base_value: 25},
          hp_regen: %{upgrade_rate: 0.3, base_value: 0.3},
          projectile_time_to_live: %{upgrade_rate: 0.15, base_value: 30}
        }
      )
    end
  end
end