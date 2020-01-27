defmodule Diep.IoWeb.GameStateChannel do
  use Diep.IoWeb, :channel

  def join("game_state:main_game", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_state", payload, socket) do
    broadcast(socket, "new_state", payload)
    {:noreply, socket}
  end

  def handle_in("new_action", _payload, socket) do
    # TODO: Handle a new_action messages
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
