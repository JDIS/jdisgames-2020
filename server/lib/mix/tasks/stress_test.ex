defmodule Mix.Tasks.StressTest do
  use Mix.Task

  @bot_count 8
  @starter_packs_base_path Path.expand("../StarterPacks")
  @starter_packs %{
    "py" => %{
      executable_name: "python",
      entrypoint_file_name: "python/run_bot.py"
    },
    "js" => %{
      executable_name: "node",
      entrypoint_file_name: "javascript/index.js"
    }
  }

  @spec run([String.t()]) :: :ok
  def run(args) do
    language =
      case args do
        [language] when language in ["js", "py"] -> language
        _ -> raise ArgumentError.exception(~s("py" or "js" must be passed as the single argument))
      end

    IO.puts("Resetting database")

    reset_database()

    IO.puts("Starting application")

    start_app()

    IO.puts("Starting bots")

    for _ <- 1..@bot_count do
      {:ok, user} = DiepIO.UsersRepository.create_user(%{name: Ecto.UUID.generate()})
      Task.async(fn -> start_bot(user.secret_key, language) end)
    end

    DiepIO.GameSupervisor.start_game(2000, "main_game")

    receive do
      :never_gonna_receive_this ->
        nil
    end

    :ok
  end

  defp start_bot(secret_key, language) do
    bot_config = @starter_packs[language]

    Port.open({:spawn_executable, System.find_executable(bot_config[:executable_name])},
      args: [bot_config[:entrypoint_file_name], "-s", secret_key],
      cd: @starter_packs_base_path,
      parallelism: true
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
