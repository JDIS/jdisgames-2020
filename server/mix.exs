defmodule Diep.MixProject do
  use Mix.Project

  def project do
    [
      app: :diep_io,
      version: "0.1.0",
      elixir: "~> 1.13.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Diep.Io.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "== 1.6.6"},
      {:phoenix_pubsub, "== 2.1.1"},
      {:phoenix_ecto, "== 4.4.0"},
      {:ecto_sql, "== 3.7.2"},
      {:postgrex, "== 0.16.2"},
      {:phoenix_html, "== 3.2.0"},
      {:phoenix_live_reload, "== 1.3.3", only: :dev},
      {:gettext, "== 0.19.1"},
      {:jason, "== 1.3.0"},
      {:plug_cowboy, "== 2.5.2"},
      {:secure_random, "== 0.5.1"},
      {:phoenix_live_dashboard, "== 0.6.5"},
      {:telemetry_poller, "== 1.0.0"},
      {:telemetry_metrics, "== 0.6.1"},
      {:plug, "== 1.13.6"},

      # dev, test
      {:credo, "== 1.6.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.1.0", only: [:dev, :test], runtime: false}
      # {:sobelow, "~> 0.9.3", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      quality: [
        "format",
        "credo --strict",
        # "sobelow --verbose",
        "dialyzer",
        "test"
      ],
      "quality.ci": [
        "test --cover --raise",
        "format --check-formatted",
        "credo --strict",
        # "sobelow --exit",
        "dialyzer"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
