defmodule DiepIOSchemas.Score do
  @moduledoc """
  A score is an instance of the amount of points a single bot/user acquired during a single game.
  It's timestamped to allow for a graph scoreboard to be built.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          game_id: integer(),
          user_id: integer(),
          score: integer()
        }

  schema "scores" do
    field(:game_id, :integer)
    field(:score, :integer)
    belongs_to(:user, DiepIOSchemas.User)

    timestamps()
  end
end
