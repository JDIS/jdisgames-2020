defmodule DiepIOWeb.AuthenticationPlug do
  @moduledoc """
  HTTP Basic Auth authentication for admin section
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    good_login = Application.fetch_env!(:diep_io, :admin_username)
    good_password = Application.fetch_env!(:diep_io, :admin_password)

    Plug.BasicAuth.basic_auth(conn, username: good_login, password: good_password)
  end
end
