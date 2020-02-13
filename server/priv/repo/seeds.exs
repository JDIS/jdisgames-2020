# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Diep.Io.Repo.insert!(%Diep.Io.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger

users = 1..10 |> Enum.each(fn i -> Diep.Io.UsersRepository.create_user(%{name: "User#{i}"}) end)
Logger.info("Seeded 10 users #{inspect(users)}")
