defmodule Diep.IoWeb.Authentication do
  @moduledoc """
  HTTP Basic Auth authentication for admin section
  """

  import Plug.Conn

  def authenticate(conn, login, password) do
    case check_login(login, password) do
      true -> conn
      false -> halt(conn)
    end
  end

  defp check_login(login, password) do
    good_login = System.get_env("ADMIN_USERNAME", "admin")
    good_password = System.get_env("ADMIN_PASSWORD", "admin")
    login == good_login and password == good_password
  end
end
