defmodule DiepIO.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:secret_key, :string, null: false)

      timestamps()
    end
  end
end
