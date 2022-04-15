defmodule Diep.Io.ScoreRepository do
  @moduledoc """
  The ScoreRepository context.
  """

  import Ecto.Query, warn: false
  alias Diep.Io.Repo

  alias Diep.Io.Users.Score

  @doc """
  Returns the list of all scores.
  """
  @spec get_scores() :: [Score.t()]
  def get_scores do
    Repo.all(Score)
  end

  @doc """
  Adds a score to the database.
  """
  @spec add_score(%{}) :: Score.t()
  def add_score(attrs) do
    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
  end
end
