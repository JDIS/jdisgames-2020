defmodule Diep.IoWeb.ScoreboardView do
  use Diep.IoWeb, :view

  def render("scoreboard.json", %{scores: scores}) do
    %{
      scores: scores
    }
  end
end
