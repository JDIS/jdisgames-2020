# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DiepIO.Repo.insert!(%DiepIO.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger
alias DiepIO.Repo
alias DiepIO.Users.{User, Score}

Repo.delete_all(Score)
Repo.delete_all(User)
:ok = 1..30 |> Enum.each(fn i -> DiepIO.UsersRepository.create_user(%{name: "User#{i}"}) end)
Logger.info("Seeded 30 users")
