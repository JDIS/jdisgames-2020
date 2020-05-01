defmodule Diep.IoWeb.ActionChannelTest do
  use Diep.IoWeb.ChannelCase

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action
  alias Diep.IoWeb.{ActionChannel, BotSocket}

  @tank_id 444
  @input %{
    tank_id: @tank_id,
    destination: [25, 34],
    purchase: nil
  }
  @action %Action{
    tank_id: @tank_id,
    destination: {25, 34},
    purchase: nil,
    target: nil
  }

  setup do
    game_name = :main_game
    :ok = ActionStorage.init(game_name)

    {:ok, _, socket} =
      BotSocket
      |> socket("user_id", %{user_id: @tank_id})
      |> subscribe_and_join(ActionChannel, "action", %{"game_name" => Atom.to_string(game_name)})

    {:ok, socket: socket, game_name: game_name}
  end

  test "pushing a new action in the action channel stores stores it in ActionStorage", %{
    socket: socket,
    game_name: game_name
  } do
    push(socket, "new", @input)
    # Needed because async
    Process.sleep(10)
    assert ActionStorage.pop_action(game_name, @tank_id) == @action
  end

  test "join/3 assigns game name as string to the socket", %{socket: socket, game_name: game_name} do
    assert socket.assigns[:game_name] == Atom.to_string(game_name)
  end

  test "join/3 returns an error when connecting to the same game twice", %{socket: socket, game_name: game_name} do
    response =
      socket
      |> subscribe_and_join(ActionChannel, "action", %{"game_name" => Atom.to_string(game_name)})

    assert response == {:error, %{error: "Already connected"}}
  end

  test "join/3 allows connecting to multiple games simultaneously", %{socket: socket, game_name: game_name} do
    assert subscribe_and_join!(socket, ActionChannel, "action", %{"game_name" => Atom.to_string(game_name) <> "2"})
  end
end
