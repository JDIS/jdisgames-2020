defmodule Diep.IoWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "game_state", Diep.IoWeb.GameStateChannel
  channel "action", Diep.IoWeb.ActionChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
