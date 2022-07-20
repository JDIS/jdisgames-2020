defmodule DiepIO.ScoreRepository do
  @moduledoc """
  The ScoreRepository context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias DiepIO.Repo

  alias DiepIOSchemas.Score

  @doc """
  Returns the list of all scores.
  """
  @spec get_scores() :: [Score.t()]
  def get_scores do
    Score
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Adds a score to the database.
  """
  @spec add_score(%{}) :: Score.t()
  def add_score(attrs) do
    %Score{}
    |> cast(attrs, [:game_id, :score, :user_id])
    |> validate_required([:game_id, :score, :user_id])
    |> Repo.insert()
  end
end
