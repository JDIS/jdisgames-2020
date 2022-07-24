defmodule Mix.Tasks.StressTest do
  @moduledoc """
  Runs a stress test on the whole system.

  Starts the server as well as 30 parallel instances of a bot.

  Which bot is started can be configured through the first and only parameter of
  the command. Allowed values are:
  - js: Starts the javascript bot (default)
  - py: Starts the python bot
  """

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

    game_name = "main_game"

    DiepIO.GameParamsRepository.save_game_params(game_name, DiepIO.GameParams.default_params())

    DiepIO.GameSupervisor.start_game(game_name)

    receive do
      :never_gonna_receive_this ->
        nil
    end

    :ok
  end

  defp start_bot(secret_key, language) do
    bot_config = @starter_packs[language]

    Port.open({:spawn_executable, System.find_executable(bot_config[:executable_name])},
      args: [bot_config[:entrypoint_file_name], "-s", secret_key, "-u", "ws://localhost:4000/socket"],
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
