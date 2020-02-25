defmodule Diep.IoWeb.GameStateChannelTest do
  use Diep.IoWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(Diep.IoWeb.SpectateSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(Diep.IoWeb.GameStateChannel, "game_state")

    {:ok, socket: socket}
  end

  test "new_state broadcasts to game_state", %{socket: socket} do
    push(socket, "new_state", %{"state" => "new"})
    assert_broadcast "new_state", %{"state" => "new"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
