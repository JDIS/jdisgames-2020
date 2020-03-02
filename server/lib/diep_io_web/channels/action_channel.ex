defmodule Diep.IoWeb.ActionChannel do
  @moduledoc false
  use Diep.IoWeb, :channel

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action

  def join("action", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("new", %{"tank_id" => _} = action, socket) do
    ActionStorage.store_action(parse_action(action, socket.assigns[:user_id]))

    {:noreply, socket}
  end

  defp parse_action(%{"destination" => destination}, user_id) do
    Action.new(user_id, destination: List.to_tuple(destination))
  end
end
