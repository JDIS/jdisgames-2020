defmodule DiepIO.Repo.Migrations.AddGlobalParams do
  use Ecto.Migration

  def up do
    create table(:global_params, primary_key: false) do
      add(:enable_scoreboard_auth, :boolean, null: false, default: false)
    end

    execute("INSERT INTO global_params (enable_scoreboard_auth) VALUES (false);")
  end

  def down do
    drop table(:global_params)
  end
end
