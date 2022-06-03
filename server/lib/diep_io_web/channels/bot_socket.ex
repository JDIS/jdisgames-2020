defmodule DiepIOWeb.BotSocket do
  alias DiepIO.UsersRepository

  use Phoenix.Socket

  ## Channels
  channel("action:*", DiepIOWeb.ActionChannel)

  def connect(%{"secret" => secret}, socket) do
    case UsersRepository.get_user_id_from_secret(secret) do
      {:ok, user_id} -> {:ok, assign(socket, :user_id, user_id)}
      {:error, reason} -> {:error, reason}
    end
  end

  def id(socket), do: "bot_socket:#{socket.assigns[:user_id]}"
end
