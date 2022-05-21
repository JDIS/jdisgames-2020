defmodule DiepIOWeb.SpectateSocket do
  use Phoenix.Socket

  ## Channels
  channel("game_state", DiepIOWeb.GameStateChannel)

  def connect(_params, socket), do: {:ok, socket}

  def id(_socket), do: nil
end
