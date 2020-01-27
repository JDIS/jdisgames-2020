defmodule Diep.IoWeb.GameStateChannel do
  @moduledoc false
  use Diep.IoWeb, :channel

  def join("game_state:main_game", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("new_state", payload, socket) do
    broadcast(socket, "new_state", payload)
    {:noreply, socket}
  end

  def handle_in("new_action", _payload, socket) do
    {:noreply, socket}
  end
end
