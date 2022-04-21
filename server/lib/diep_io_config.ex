defmodule DiepIoConfig do
  @spec database_url() :: String.t()
  def database_url, do: System.fetch_env!("DIEP_DATABASE_URL")

  @spec database_pool_size() :: integer()
  def database_pool_size do
    "DIEP_POOL_SIZE"
    |> System.get_env("10")
    |> String.to_integer()
  end

  @spec secret_key_base() :: String.t()
  def secret_key_base, do: System.fetch_env!("DIEP_SECRET_KEY_BASE")

  @spec port() :: integer()
  def port do
    "DIEP_PORT"
    |> System.get_env("4000")
    |> String.to_integer()
  end

  @spec admin_username() :: String.t()
  def admin_username, do: System.fetch_env!("DIEP_ADMIN_USERNAME")

  @spec admin_password() :: String.t()
  def admin_password, do: System.fetch_env!("DIEP_ADMIN_PASSWORD")

  @spec custom_badges_location() :: String.t()
  def custom_badges_location, do: System.get_env("DIEP_CUSTOM_BADGES_LOCATION", "./badges")
end
