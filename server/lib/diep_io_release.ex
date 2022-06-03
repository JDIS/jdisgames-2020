defmodule DiepIORelease do
  @moduledoc """
  Module to do operations (such as database seeding and/or migration) before launching the application
  in a context where mix is not accessible (release).
  """
  use Boundary, deps: [DiepIO], exports: []

  alias DiepIO.UsersRepository

  @start_apps [
    :postgrex,
    :ecto
  ]

  @app :diep_io

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _ ->
          1..30 |> Enum.each(fn i -> UsersRepository.create_user(%{name: "User#{i}"}) end)
        end)
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))

    :ok
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    IO.puts("Loading DiepIO...")
    :ok = Application.ensure_loaded(@app)

    IO.puts("Starting dependencies...")
    Enum.each(@start_apps, &Application.ensure_all_started/1)
  end
end
