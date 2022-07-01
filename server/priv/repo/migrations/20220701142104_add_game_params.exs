defmodule DiepIO.Repo.Migrations.AddGameParams do
  use Ecto.Migration

  def change do
    create table(:game_params, primary_key: false) do
      add(:game_name, :string, null: false, primary_key: true)
      add(:number_of_ticks, :integer, null: false)
      add(:max_debris_count, :integer, null: false)
      add(:max_debris_generation_rate, :float, null: false)
      add(:score_multiplier, :float, null: false)
    end
  end
end
