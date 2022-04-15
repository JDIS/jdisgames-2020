defmodule Diep.IoWeb.AuthenticationPlug do
  @moduledoc """
  HTTP Basic Auth authentication for admin section
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    good_login = System.get_env("ADMIN_USERNAME", "admin")
    good_password = System.get_env("ADMIN_PASSWORD", "admin")

    Plug.BasicAuth.basic_auth(conn, username: good_login, password: good_password)
  end
end
