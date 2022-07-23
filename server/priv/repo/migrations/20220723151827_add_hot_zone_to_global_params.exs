defmodule DiepIO.Repo.Migrations.AddHotZoneToGlobalParams do
  use Ecto.Migration

  def change do
    alter table(:game_params) do
      add(:hot_zone_points, :integer, null: false, default: 6)
    end
  end
end
