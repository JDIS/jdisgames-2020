defmodule Diep.IoWeb.PageController do
  use Diep.IoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
