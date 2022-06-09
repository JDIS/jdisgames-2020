defmodule Mix.Tasks.StressTest do
  use Mix.Task

  @bot_count 30

  def run(_) do
    IO.puts("Resetting database")

    reset_database()

    IO.puts("Starting application")

    start_app()

    IO.puts("Starting bots")

    for _ <- 1..@bot_count do
      {:ok, user} = DiepIO.UsersRepository.create_user(%{name: Ecto.UUID.generate()})
      Task.async(fn -> start_bot(user.secret_key) end)
    end

    DiepIO.GameSupervisor.start_game(2000, "main_game")

    receive do
      :never_gonna_receive_this ->
        nil
    end

    :ok
  end

  defp start_bot(secret_key) do
    Port.open({:spawn_executable, System.find_executable("python")},
      args: ["../StarterPacks/python/run_bot.py", "-s", secret_key]
    )
  end

  defp start_app do
    Task.start(fn -> Mix.Task.run("phx.server") end)
    Process.sleep(2000)
  end

  defp reset_database do
    Mix.Task.run("ecto.reset")
  end
end
