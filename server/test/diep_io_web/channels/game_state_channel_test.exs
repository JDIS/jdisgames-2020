defmodule DiepIOWeb.GameStateChannelTest do
  @moduledoc false

  use DiepIOWeb.ChannelCase

  alias DiepIO.PubSub
  alias DiepIO.Core.{Clock, GameState}

  setup do
    game_name = :main_game

    {:ok, _, socket} =
      DiepIOWeb.SpectateSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(DiepIOWeb.GameStateChannel, "game_state:#{game_name}")

    {:ok, socket: socket, game_name: game_name}
  end

  test "new_state pushes to game_state", %{game_name: game_name} do
    game_params = %{
      max_debris_count: 400,
      max_debris_generation_rate: 0.15,
      score_multiplier: 1
    }

    state = GameState.new(game_name, [], 1, false, false, Clock.new(1, 1), game_params)
    PubSub.broadcast!("new_state:#{game_name}", {:new_state, state})
    assert_push("new_state", ^state)
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push("broadcast", %{"some" => "data"})
  end
end
