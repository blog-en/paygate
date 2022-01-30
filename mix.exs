defmodule Paygate.MixProject do
  use Mix.Project

  def project do
    [
      app: :paygate,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [
        tool: ExCoveralls
      ],
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      releases: [
        paygate: [
          include_executables_for: [:unix],
          applications: [
            runtime_tools: :permanent
          ]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Paygate.Application, []},
      extra_applications: [:logger, :runtime_tools, :gen_state_machine]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  #  defp elixirc_paths(:dev), do: ["lib", "lib_dev", "lib_main"]
  defp elixirc_paths(_), do: ["lib", "lib_main", "tasks"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.6"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_dashboard, "~> 0.6"},
      #      {:telemetry_metrics, "~> 0.6"},
      #      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.5"},
      {:prom_ex, "~> 1.6"},
      {:vapor, "~> 0.10.0"},
      {:httpoison, "~> 1.8"},
      {:uuid, "~> 1.1"},
      {:gen_stage, "~> 1.1"},
      {:gen_state_machine, "~> 3.0"},
      {:open_api_spex, "~> 3.10"},
      {:ecto_sql, "~> 3.7"},
      {:myxql, ">= 0.0.0"},
      {:tzdata, "~> 1.1"},

      # dev and test only
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: [:test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "load_vapor_config", "ecto.setup"],
      db_recreate: ["load_vapor_config", "ecto.drop", "ecto.create", "ecto.migrate"],
      "ecto.setup": ["ecto.create", "ecto.migrate"]
    ]
  end

  defp dialyzer() do
    [
      plt_add_deps: :app_tree,
      plt_add_apps: [:mix, :ex_unit],
      plt_ignore_apps: [:credo],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end
