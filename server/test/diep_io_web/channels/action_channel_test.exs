defmodule DiepIOWeb.ActionChannelTest do
  @moduledoc false

  use DiepIOWeb.ChannelCase

  import Phoenix.ChannelTest, except: [{:subscribe_and_join, 2}]

  alias DiepIO.ActionStorage
  alias DiepIO.Core.Action
  alias DiepIOWeb.{ActionChannel, BotSocket}

  @tank_id 444
  @input %{
    tank_id: @tank_id,
    destination: [25, 34],
    target: [25, 34],
    purchase: "speed"
  }
  @action %Action{
    tank_id: @tank_id,
    destination: {25, 34},
    purchase: :speed,
    target: {25, 34}
  }

  setup %{test: test} do
    game_name = test
    :ok = ActionStorage.init(game_name)

    {:ok, _, socket} =
      BotSocket
      |> socket("user_id", %{user_id: @tank_id})
      |> subscribe_and_join(game_name)

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

  test "join/3 returns an error when connecting to the same game twice", %{
    socket: socket,
    game_name: game_name
  } do
    response = subscribe_and_join(socket, game_name)

    assert response == {:error, %{error: "Already connected"}}
  end

  test "join/3 allows connecting to multiple games simultaneously", %{
    socket: socket,
    game_name: game_name
  } do
    assert subscribe_and_join(socket, to_string(game_name) <> "2")
  end

  defp subscribe_and_join(socket, game_name), do: subscribe_and_join(socket, ActionChannel, "action:#{game_name}")
end
