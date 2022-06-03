defmodule DiepIOWeb.ScoreboardView do
  use DiepIOWeb, :view

  def render("scoreboard.json", %{scores: scores}) do
    %{
      scores: scores
    }
  end
end
