defmodule Diep.IoWeb.BotSocketTest do
  use Diep.IoWeb.ChannelCase

  alias Diep.Io.Repo
  alias Diep.Io.Users.User
  alias Diep.IoWeb.BotSocket

  @a_secret_key "secret_key"
  @a_user %{name: "a_name", secret_key: @a_secret_key}

  setup do
    %User{}
    |> User.changeset(@a_user)
    |> Repo.insert()

    {:ok, user: @a_user}
  end

  test "connect/2 with authentication secret accepts connection", %{user: %{secret_key: secret_key}} do
    assert {:ok, _} = connect(BotSocket, %{secret: secret_key}, %{})
  end

  test "connect/2 with wrong secret refuses connection", %{user: %{secret_key: secret_key}} do
    assert :error = connect(BotSocket, %{secret: secret_key <> "1"}, %{})
  end
end
