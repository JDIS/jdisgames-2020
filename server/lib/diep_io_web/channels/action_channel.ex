defmodule DiepIOWeb.ActionChannel do
  @moduledoc false
  use DiepIOWeb, :channel

  alias DiepIO.ActionStorage
  alias DiepIO.Core.Action
  alias DiepIOWeb.Presence

  intercept(["presence_diff"])

  def join("action:" <> game_name, _payload, socket) do
    if is_already_connected?(socket, game_name) do
      {:error, %{error: "Already connected"}}
    else
      send(self(), :after_join)
      {:ok, assign(socket, :game_name, game_name)}
    end
  end

  def handle_info(:after_join, %{assigns: %{user_id: user_id, game_name: game_name}} = socket) do
    {:ok, _} = Presence.track(socket, user_id, %{connected: game_name})

    {:noreply, socket}
  end

  def handle_out("presence_diff", _payload, socket), do: {:noreply, socket}

  def handle_in("new", action, %{assigns: %{user_id: user_id, game_name: game_name}} = socket) do
    action
    |> parse_action(user_id)
    |> store_action(game_name)

    {:noreply, socket}
  end

  def handle_in("get_id", _, socket) do
    {:reply, {:ok, %{"id" => socket.assigns.user_id}}, socket}
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
      "projectile_time_to_live" -> :projectile_time_to_live
      "projectile_speed" -> :projectile_speed
      _ -> nil
    end
  end

  defp is_already_connected?(%{assigns: %{user_id: user_id}} = socket, game_name) do
    case Presence.get_by_key(socket, user_id) do
      [] ->
        false

      %{metas: metas} ->
        Enum.any?(metas, fn %{connected: connected_game} -> connected_game == game_name end)
    end
  end
end
