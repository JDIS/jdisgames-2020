defmodule Diep.Io.Users.Score do
  @moduledoc """
  A score is an instance of the amount of points a single bot/user acquired during a single game.
  It's timestamped to allow for a graph scoreboard to be built.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:game_id, :user_id, :score, :inserted_at]}

  @type t :: %__MODULE__{
          game_id: integer(),
          user_id: integer(),
          score: integer()
        }

  schema "scores" do
    field :game_id, :integer
    field :score, :integer
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:game_id, :score, :user_id])
    |> validate_required([:game_id, :score, :user_id])
  end
end
