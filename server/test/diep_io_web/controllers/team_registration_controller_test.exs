defmodule DiepIOWeb.TeamRegistrationControllerTest do
  use DiepIOWeb.ConnCase, async: false

  alias DiepIO.UsersRepository

  test "GET /team-registration", %{conn: conn} do
    response =
      conn
      |> get(Routes.team_registration_path(conn, :new))

    assert html_response(response, 200) =~ "<h1>Team registration</h1>"
  end

  describe "POST /team-registration/register" do
    test "Displays secret-key on success", %{conn: conn} do
      params = %{"user" => %{"name" => "test"}}

      response =
        conn
        |> post(Routes.team_registration_path(conn, :create), params)

      assert html_response(response, 200) =~ "Team test's secret key"
    end

    test "Displays error message on error", %{conn: conn} do
      params = %{"user" => %{"name" => "test"}}

      UsersRepository.create_user(params["user"])

      response =
        conn
        |> post(Routes.team_registration_path(conn, :create), params)

      assert html_response(response, 200) =~ "has already been taken"
    end
  end
end
