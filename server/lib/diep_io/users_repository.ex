defmodule Diep.Io.UsersRepository do
  @moduledoc """
  The Users context.
  """

  alias Diep.Io.Repo
  alias Diep.Io.Users.User
  require Logger

  @spec list_users() :: [User.t()]
  def list_users do
    Repo.all(User)
  end

  @doc """
    Returns
    {:ok, 123} in case the secret matches user 123 in the DB.
    else return {:error, "Not found"}
  """
  @spec get_user_id_from_secret(String.t()) :: {:ok, integer} | {:error, String.t()}
  def get_user_id_from_secret(secret) do
    case Repo.get_by(User, secret_key: secret) do
      nil -> {:error, "Not found"}
      user -> {:ok, user.id}
    end
  end

  @doc """
  Generates a secret_key and creates a user. Logs the status of the operation.
  Returns
      {:ok, %User{}} On success
      {:error, %Ecto.Changeset{}} On error
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t(User.t())}
  def create_user(attrs) do
    attrs_with_secret_key =
      attrs
      |> Map.put(:secret_key, SecureRandom.uuid())
      |> keys_to_atom()

    result =
      %User{}
      |> User.changeset(attrs_with_secret_key)
      |> Repo.insert()

    case result do
      {:ok, user} ->
        Logger.info("Created user #{inspect(user)}")

      {:error, error} ->
        Logger.error("""
        Error when creating a new user #{inspect(attrs)}: #{inspect(error)}
        """)
    end

    result
  end

  defp keys_to_atom(map) do
    Enum.reduce(map, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end
end
