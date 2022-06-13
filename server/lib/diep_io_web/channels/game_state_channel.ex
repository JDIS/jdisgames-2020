defmodule DiepIOWeb.GameStateChannel do
  @moduledoc false
  use DiepIOWeb, :channel

  alias DiepIO.Core.GameState
  alias DiepIO.PubSub

  @impl true
  def join("game_state:" <> game_name, _payload, socket) do
    PubSub.subscribe("new_state:#{game_name}")
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_state, %GameState{} = new_state}, socket) do
    broadcast(socket, "new_state", new_state)

    {:noreply, socket}
  end
end
