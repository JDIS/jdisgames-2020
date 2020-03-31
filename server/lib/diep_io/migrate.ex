defmodule Diep.Io.Release do
  @moduledoc """
  Module to do operations (such as database seeding and/or migration) before launching the application
  in a context where mix is not accessible (release).
  """
  @app :diep_io

  alias Diep.Io.UsersRepository

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _ ->
          1..30 |> Enum.each(fn i -> UsersRepository.create_user(%{name: "User#{i}"}) end)
        end)
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
