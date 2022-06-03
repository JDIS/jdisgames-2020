defmodule DiepIOWeb.GameStateChannelTest do
  @moduledoc false

  use DiepIOWeb.ChannelCase

  alias DiepIO.PubSub
  alias DiepIO.Core.{Clock, GameState}

  setup do
    game_name = :main_game

    {:ok, _, socket} =
      socket(DiepIOWeb.SpectateSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(DiepIOWeb.GameStateChannel, "game_state", %{
        "game_name" => Atom.to_string(game_name)
      })

    {:ok, socket: socket, game_name: game_name}
  end

  test "new_state broadcasts to game_state", %{game_name: game_name} do
    state = GameState.new(game_name, [], 1, false, false, Clock.new(1, 1))
    PubSub.broadcast!("new_state", {:new_state, state})
    assert_broadcast("new_state", ^state)
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push("broadcast", %{"some" => "data"})
  end

  test "join/3 assigns game name as string to the socket", %{socket: socket, game_name: game_name} do
    assert socket.assigns[:game_name] == to_string(game_name)
  end

  test "broadcasts are only pushed to clients who subscribed to the corresponding game", %{
    game_name: game_name
  } do
    game_name = String.to_atom(to_string(game_name) <> "2")
    state = GameState.new(game_name, [], 1, false, false, Clock.new(1, 1))
    PubSub.broadcast!("new_state", {:new_state, state})

    refute_push("new_state", ^state)
  end
end
