defmodule Diep.IoWeb.ActionChannelTest do
  use Diep.IoWeb.ChannelCase

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action

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
    {:ok, _, socket} =
      socket(Diep.IoWeb.BotSocket, "user_id", %{user_id: @tank_id})
      |> subscribe_and_join(Diep.IoWeb.ActionChannel, "action")

    {:ok, socket: socket}
  end

  test "pushing a new action in the action channel stores stores it in ActionStorage", %{socket: socket} do
    push(socket, "new", @input)
    # Needed because async
    Process.sleep(10)
    assert ActionStorage.get_action(@tank_id) == @action
  end
end
