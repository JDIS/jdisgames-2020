defmodule DiepIOWeb.ScoreboardViewTest do
  @moduledoc false

  use DiepIOWeb.ConnCase, async: true

  alias DiepIOWeb.ScoreboardView

  test "render(scoreboard.json) formats like it should" do
    render =
      ScoreboardView.render("scoreboard.json", %{
        scores: [%{game_id: 3, user_id: 5, score: 65.78}]
      })

    assert render == %{scores: [%{game_id: 3, user_id: 5, score: 65.78}]}
  end

  test "render(scoreboard.json) cannot be called with wrong arguments" do
    assert_raise(Phoenix.Template.UndefinedError, fn ->
      ScoreboardView.render("scoreboard.json", %{})
    end)
  end
end
