defmodule Diep.IoWeb.ActionChannel do
  @moduledoc false
  use Diep.IoWeb, :channel

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action

  def join("action", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("new", action, socket) do
    action
    |> parse_action(socket.assigns[:user_id])
    |> store_action()

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

  defp store_action(action) do
    # TODO: handle multiple game names
    true = ActionStorage.store_action(:main_game, action)
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
