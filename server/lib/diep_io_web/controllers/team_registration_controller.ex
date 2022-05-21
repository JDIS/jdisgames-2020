defmodule DiepIOWeb.TeamRegistrationController do
  use DiepIOWeb, :controller

  alias DiepIO.UsersRepository

  def new(conn, _params) do
    conn
    |> render("new.html", changeset: UsersRepository.new_user())
  end

  def create(conn, params) do
    case UsersRepository.create_user(params["user"]) do
      {:ok, new_user} ->
        conn
        |> render("confirmation.html",
          team_data: %{secret_key: new_user.secret_key, name: new_user.name}
        )

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end
end
