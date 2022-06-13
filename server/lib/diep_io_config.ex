defmodule DiepIOConfig do
  @moduledoc """
  Home of all the application's external configuration (typically environment variables).

  All functions contained in this module should return the values in their ready-to-use form. This means all parsing
  (eg. parsing strings to ints) should be done here instead of expecting the caller to do it.
  """
  use Boundary, deps: [], exports: []

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
end
