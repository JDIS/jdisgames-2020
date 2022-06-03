defmodule DiepIOWeb.GameStateChannel do
  @moduledoc false
  use DiepIOWeb, :channel

  alias DiepIO.Core.GameState
  alias DiepIO.PubSub

  @impl true
  def join("game_state", %{"game_name" => game_name} = _payload, socket) do
    PubSub.subscribe("new_state")
    {:ok, assign(socket, :game_name, game_name)}
  end

  @impl true
  def handle_info({:new_state, %GameState{} = new_state}, socket) do
    if to_string(new_state.name) == socket.assigns[:game_name] do
      broadcast(socket, "new_state", new_state)
    end

    {:noreply, socket}
  end
end
