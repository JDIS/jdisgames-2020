defmodule DiepIO.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add(:game_id, :bigint, null: false)
      add(:score, :integer, null: false)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:scores, [:user_id]))
  end
end
