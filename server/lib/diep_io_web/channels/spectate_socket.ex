defmodule Diep.IoWeb.SpectateSocket do
  use Phoenix.Socket

  ## Channels
  channel "game_state", Diep.IoWeb.GameStateChannel

  def connect(_params, socket), do: {:ok, socket}

  def id(_socket), do: nil
end
