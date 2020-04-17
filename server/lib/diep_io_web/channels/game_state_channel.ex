defmodule Diep.IoWeb.GameStateChannel do
  @moduledoc false
  use Diep.IoWeb, :channel

  alias Diep.Io.Core.GameState

  def join("game_state", %{"game_name" => game_name} = _payload, socket) do
    {:ok, assign(socket, :game_name, game_name)}
  end

  def handle_in("new_state", payload, socket) do
    broadcast(socket, "new_state", payload)
    {:noreply, socket}
  end

  def handle_out("new_state", %GameState{name: name} = payload, socket) do
    if to_string(name) == ":" <> socket.assigns[:game_name] do
      push(socket, "new_state", payload)
    end

    {:noreply, socket}
  end
end
