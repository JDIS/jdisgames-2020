defmodule Diep.IoWeb.ActionChannel do
  @moduledoc false
  use Diep.IoWeb, :channel

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action

  def join("action", %{"game_name" => game_name} = _payload, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :game_name, game_name)}
  end

  def handle_info(:after_join, socket) do
    push(socket, "id", %{id: socket.assigns[:user_id]})
    {:noreply, socket}
  end

  def handle_in("new", action, socket) do
    action
    |> parse_action(socket.assigns[:user_id])
    |> store_action(socket.assigns[:game_name])

    {:noreply, socket}
  end

  defp parse_action(action, tank_id) do
    Action.new(tank_id,
      destination: parse_position(action, "destination"),
      target: parse_position(action, "target"),
      purchase: parse_purchase(action, "purchase")
    )
  end

  defp parse_position(action, key) do
    case Map.get(action, key) do
      nil -> nil
      position -> List.to_tuple(position)
    end
  end

  defp store_action(action, game_name) do
    true = ActionStorage.store_action(String.to_existing_atom(game_name), action)
  end

  defp parse_purchase(action, key) do
    case Map.get(action, key) do
      "speed" -> :speed
      "fire_rate" -> :fire_rate
      "projectile_damage" -> :projectile_damage
      "max_hp" -> :max_hp
      "body_damage" -> :body_damage
      "hp_regen" -> :hp_regen
      _ -> nil
    end
  end
end
